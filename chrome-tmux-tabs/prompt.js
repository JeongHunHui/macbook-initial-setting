const tabId = Number(new URLSearchParams(location.search).get("tabId"));
const input = document.getElementById("name");

function submit() {
  chrome.runtime.sendMessage({ type: "group_name", tabId, name: input.value.trim() });
  window.close();
}

document.getElementById("ok").onclick = submit;
document.getElementById("cancel").onclick = () => window.close();
input.addEventListener("keydown", (e) => {
  if (e.key === "Enter") submit();
  if (e.key === "Escape") window.close();
});
input.focus();
