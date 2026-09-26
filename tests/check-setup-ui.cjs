const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const html = fs.readFileSync('SETUP.html', 'utf8');
const code = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const modules = ['system', 'cli', 'apps', 'dock', 'terminal', 'codex', 'common'];
const boxes = modules.map(value => ({value, checked: true, addEventListener() {}}));
const buttons = ['command', 'plan', 'prompt'].map(view => ({dataset: {view}, classList: {toggle() {}}}));
const output = {}, summary = {}, copy = {};
const context = {document: {
  querySelectorAll: selector => selector.startsWith('input') ? boxes : buttons,
  querySelector: selector => ({'#output': output, '#summary': summary, '#copy': copy})[selector],
}, navigator: {clipboard: {writeText: async () => {}}}, setTimeout};
vm.createContext(context);
vm.runInContext(code, context);
assert.match(output.textContent, /MAC_INIT_MODULES="system,cli,apps,dock,terminal,codex,common"/);
boxes.forEach(b => b.checked = false);
vm.runInContext('render()', context);
assert.equal(copy.disabled, true);
assert.doesNotMatch(output.textContent, /bash/);
boxes.find(b => b.value === 'codex').checked = true;
buttons.find(b => b.dataset.view === 'plan').onclick();
assert.match(output.textContent, /MAC_INIT_MODULES="codex" bash \.\/setup.sh --plan/);
buttons.find(b => b.dataset.view === 'prompt').onclick();
assert.match(output.textContent, /선택 모듈: codex/);
assert.equal(copy.disabled, false);
for (const file of ['SETUP.html', 'index.html']) {
  const source = fs.readFileSync(file, 'utf8');
  for (const match of source.matchAll(/<script>([\s\S]*?)<\/script>/g)) new vm.Script(match[1]);
  for (const match of source.matchAll(/href="([^"#]+)"/g)) {
    if (!match[1].includes('://')) assert.ok(fs.existsSync(match[1]), `broken link: ${file} -> ${match[1]}`);
  }
}
console.log('HTML syntax, links, empty selection, plan, prompt: PASS');
