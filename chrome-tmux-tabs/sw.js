// tmux-tabs — 탭/그룹/창 조작. 자동 접기(활성 그룹만 펴짐)는 상시 동작.

async function activeTab() {
  const [t] = await chrome.tabs.query({ active: true, currentWindow: true });
  return t;
}
async function winTabs() {
  return chrome.tabs.query({ currentWindow: true });
}
async function normalWindows() {
  return chrome.windows.getAll({ windowTypes: ["normal"] });
}
async function workAreaOf(win) {
  const ds = await chrome.system.display.getInfo();
  const cx = win.left + win.width / 2, cy = win.top + win.height / 2;
  const hit = ds.find((d) =>
    cx >= d.bounds.left && cx < d.bounds.left + d.bounds.width &&
    cy >= d.bounds.top && cy < d.bounds.top + d.bounds.height);
  return (hit || ds.find((d) => d.isPrimary) || ds[0]).workArea;
}
async function tileEven() {
  const wins = await normalWindows();
  if (!wins.length) return;
  const area = await workAreaOf(await chrome.windows.getCurrent());
  wins.sort((a, b) => a.left - b.left);
  const w = Math.floor(area.width / wins.length);
  for (let i = 0; i < wins.length; i++)
    await chrome.windows.update(wins[i].id, { state: "normal", left: area.left + i * w, top: area.top, width: w, height: area.height });
}

const leftWide = new Map(); // windowId -> 현재 넓게 상태 여부 (재시작 시 초기화돼도 무방)

// 방문 히스토리(뒤로/앞으로)는 chrome.storage.session 에 저장한다.
// MV3 서비스워커는 수시로 꺼졌다 켜지는데, 메모리에만 두면 그때마다 히스토리가 날아가 ⌥O/⌥P 가 먹통이 된다.
// HK: windowId -> {stack:[tabId], idx}.  NK: 우리 이동으로 곧 들어올 활성화 표시(중복 push 방지).
const HK = "hist", NK = "nav";
async function loadAll() { return (await chrome.storage.session.get(HK))[HK] || {}; }
async function saveAll(all) { await chrome.storage.session.set({ [HK]: all }); }

// 히스토리 수정을 한 번에 하나씩만 하도록 직렬화한다.
// 탭을 닫으면 onRemoved 와 onActivated 가 거의 동시에 터지는데, 둘 다 히스토리를
// 읽고-고치고-쓰면 서로의 결과를 덮어써서(경쟁 상태) 히스토리가 깨진다. 그래서 잠근다.
let lock = Promise.resolve();
function withLock(fn) { const run = lock.then(fn, fn); lock = run.catch(() => {}); return run; }

async function goHist(step) {
  const target = await withLock(async () => {
    const win = await chrome.windows.getCurrent();
    const all = await loadAll();
    const h = all[win.id] || { stack: [], idx: -1 };
    const next = h.idx + step;
    if (next < 0 || next >= h.stack.length) return null;
    h.idx = next;
    all[win.id] = h;
    await chrome.storage.session.set({ [HK]: all, [NK]: { windowId: win.id, tabId: h.stack[h.idx] } });
    return h.stack[h.idx];
  });
  if (target != null) await chrome.tabs.update(target, { active: true }).catch(() => {});
}

// 새 탭(NTP)이 크롬 프리렌더 교체로 id가 바뀌는 경우 방어: 실패하면 같은 위치 탭으로 재시도
async function withTab(id, fallbackIndex, fn) {
  try { return await fn(id); }
  catch {
    const alt = (await winTabs()).find((x) => x.index === fallbackIndex);
    if (alt) return fn(alt.id);
  }
}

const handlers = {
  async next_tab() { const ts = await winTabs(); const c = ts.find((t) => t.active); await chrome.tabs.update(ts[(c.index + 1) % ts.length].id, { active: true }); },
  async prev_tab() { const ts = await winTabs(); const c = ts.find((t) => t.active); await chrome.tabs.update(ts[(c.index - 1 + ts.length) % ts.length].id, { active: true }); },
  async tab_back() { await goHist(-1); },
  async tab_forward() { await goHist(1); },
  async duplicate_tab() { const t = await activeTab(); await chrome.tabs.duplicate(t.id); },
  async reopen_closed() { await chrome.sessions.restore(); },
  async close_and_reopen() { const t = await activeTab(); await chrome.tabs.remove(t.id); await chrome.sessions.restore(); },
  async toggle_left_width() {
    const win = await chrome.windows.getCurrent();
    const area = await workAreaOf(win);
    const wide = !leftWide.get(win.id);
    leftWide.set(win.id, wide);
    const width = Math.floor(area.width * (wide ? 0.66 : 0.33));
    await chrome.windows.update(win.id, { state: "normal", left: area.left, top: area.top, width, height: area.height });
  },

  async group_with_name() {
    const t = await activeTab();
    await chrome.windows.create({ url: chrome.runtime.getURL(`prompt.html?tabId=${t.id}`), type: "popup", width: 340, height: 150 });
  },
  async new_tab_in_group() {
    const t = await activeTab();
    const inGroup = t.groupId !== chrome.tabGroups.TAB_GROUP_ID_NONE;
    // 비활성으로 만들어 onActivated(자동접기)가 그룹 편입 전에 먼저 도는 race 방지
    const nt = await chrome.tabs.create({ index: t.index + 1, active: !inGroup });
    if (inGroup) {
      await withTab(nt.id, nt.index, async (id) => {
        await chrome.tabs.group({ tabIds: [id], groupId: t.groupId });
        await chrome.tabs.update(id, { active: true }); // 그룹에 넣은 뒤 활성화 → 자동접기가 올바르게 폄
      });
    }
  },

  async collapse_all() { const gs = await chrome.tabGroups.query({ windowId: chrome.windows.WINDOW_ID_CURRENT }); for (const g of gs) await chrome.tabGroups.update(g.id, { collapsed: true }); },

  async break_pane() { const t = await activeTab(); await chrome.windows.create({ tabId: t.id }); },
  async tile_even() { await tileEven(); },
};

// 자동 접기(상시): 탭 전환할 때마다 활성 그룹만 펴고 나머지 접기 + 뒤로/앞으로 히스토리 갱신
chrome.tabs.onActivated.addListener(async ({ tabId, windowId }) => {
  await withLock(async () => {
    const nav = (await chrome.storage.session.get(NK))[NK];
    const all = await loadAll();
    const h = all[windowId] || { stack: [], idx: -1 };
    if (nav && nav.windowId === windowId && nav.tabId === tabId) {
      await chrome.storage.session.remove(NK); // 우리가 ⌥O/⌥P로 옮긴 것 → 히스토리 그대로, push 안 함
    } else if (h.stack[h.idx] !== tabId) {
      h.stack = h.stack.slice(0, h.idx + 1); // 뒤로 갔다가 다른 탭을 직접 클릭하면 그 이후 앞으로 기록은 버림
      h.stack.push(tabId);
      h.idx = h.stack.length - 1;
      if (h.stack.length > 50) { h.stack.shift(); h.idx--; }
      all[windowId] = h;
      await saveAll(all);
    }
  });

  const t = await chrome.tabs.get(tabId).catch(() => null);
  if (!t) return;
  const gs = await chrome.tabGroups.query({ windowId });
  for (const g of gs) {
    const collapse = g.id !== t.groupId;
    if (g.collapsed !== collapse) await chrome.tabGroups.update(g.id, { collapsed: collapse }).catch(() => {});
  }
});

chrome.tabs.onRemoved.addListener((tabId, { windowId }) => {
  withLock(async () => {
    const all = await loadAll();
    const h = all[windowId];
    if (!h) return;
    const removedBefore = h.stack.slice(0, h.idx + 1).filter((id) => id === tabId).length;
    h.stack = h.stack.filter((id) => id !== tabId);
    h.idx -= removedBefore;
    all[windowId] = h;
    await saveAll(all);
  });
});

// 이름 입력 팝업 → 그룹 생성/이름변경
chrome.runtime.onMessage.addListener((msg) => {
  if (msg?.type !== "group_name") return;
  (async () => {
    const t = await chrome.tabs.get(msg.tabId);
    let gid = t.groupId;
    if (gid === chrome.tabGroups.TAB_GROUP_ID_NONE) gid = await chrome.tabs.group({ tabIds: [t.id] });
    await chrome.tabGroups.update(gid, { title: msg.name || undefined });
  })().catch((e) => console.error("group_name", e));
});

if (chrome.commands?.onCommand) {
  chrome.commands.onCommand.addListener((cmd) => { handlers[cmd]?.().catch((e) => console.error(cmd, e)); });
}
