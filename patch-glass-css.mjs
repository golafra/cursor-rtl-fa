import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const MARKER_START = '/* Custom UI Style Start */';
const MARKER_END = '/* Custom UI Style End */';
const PATCH_TAG = 'cursor-rtl-fa';

function stylesheetToCss(stylesheet) {
  function nested(props, prefix = '') {
    let css = '';
    for (const [key, value] of Object.entries(props)) {
      switch (typeof value) {
        case 'string':
        case 'number':
          css += `${key}:${value};`;
          break;
        case 'object':
          if (value) css += `${key}{${nested(value)}}`;
          break;
      }
    }
    return css;
  }

  let css = '';
  for (const [selector, rules] of Object.entries(stylesheet)) {
    let body = '';
    switch (typeof rules) {
      case 'string':
        body = rules;
        break;
      case 'object':
        body = nested(rules);
        break;
      default:
        continue;
    }
    css += `${selector}{${body}}`;
  }
  return css;
}

function removeExistingPatch(content) {
  const blockRe = /\/\* Custom UI Style Start \*\/[\s\S]*?\/\* Custom UI Style End \*\//;
  return content.replace(blockRe, '').trimEnd();
}

function buildPatchBlock(css) {
  return `\n${MARKER_START}\n/* ${PATCH_TAG}: Agents Window (workbench.glass.main.css) */\n${css}\n${MARKER_END}\n`;
}

function resolveCursorGlassCssPath() {
  const localAppData = process.env.LOCALAPPDATA;
  if (!localAppData) return null;

  const candidates = [
    path.join(localAppData, 'Programs', 'cursor', 'resources', 'app', 'out', 'vs', 'workbench', 'workbench.glass.main.css'),
    path.join(localAppData, 'Programs', 'Cursor', 'resources', 'app', 'out', 'vs', 'workbench', 'workbench.glass.main.css'),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function parseArgs(argv) {
  const args = { snippet: path.join(__dirname, 'settings-snippet.json') };
  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === '--snippet' && argv[i + 1]) {
      args.snippet = argv[++i];
    }
  }
  return args;
}

function main() {
  const { snippet: snippetPath } = parseArgs(process.argv);

  if (!fs.existsSync(snippetPath)) {
    console.error(`Error: snippet not found: ${snippetPath}`);
    process.exit(1);
  }

  const snippet = JSON.parse(fs.readFileSync(snippetPath, 'utf8'));
  const agentsStylesheet = snippet['custom-ui-style.agents.stylesheet'];
  if (!agentsStylesheet || Object.keys(agentsStylesheet).length === 0) {
    console.error('Error: custom-ui-style.agents.stylesheet is empty in snippet.');
    process.exit(1);
  }

  const glassCssPath = resolveCursorGlassCssPath();
  if (!glassCssPath) {
    console.error('Error: workbench.glass.main.css not found. Is Cursor installed?');
    process.exit(1);
  }

  const css = stylesheetToCss(agentsStylesheet);
  const patchBlock = buildPatchBlock(css);
  const original = fs.readFileSync(glassCssPath, 'utf8');
  const cleaned = removeExistingPatch(original);
  const patched = cleaned + patchBlock;

  const backupPath = `${glassCssPath}.${PATCH_TAG}.backup`;
  if (!fs.existsSync(backupPath)) {
    fs.copyFileSync(glassCssPath, backupPath);
    console.log(`Backup: ${backupPath}`);
  }

  fs.writeFileSync(glassCssPath, patched, 'utf8');
  console.log(`Patched: ${glassCssPath}`);
  console.log('Restart Cursor completely and reopen Agents Window.');
}

main();
