// Makes a version badge for the wiki. New features are badged with the version development is working
// toward, which is the version in scpui_system_core.lua (development is bumped right after each release).
//   node wiki-badges.js            make the badge for the current version and add it to the legend in
//                                  Tables.md, then print the markdown to paste
//   node wiki-badges.js 1.2.0      same, for a given version
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..', '..');
const wiki = path.join(root, 'wiki');
const badges = path.join(wiki, 'images', 'badges');
const legendPage = path.join(wiki, 'Tables.md');
const BASE = 'https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/';
const BADGE_RE = /!\[[^\]]*\]\(https:\/\/raw\.githubusercontent\.com\/wiki\/MjnMixael\/SCPUI\/images\/badges\/scpui-([^)]+)\.svg\)/g;

let version = process.argv[2];
if (!version) {
	const core = fs.readFileSync(path.join(root, 'content', 'data', 'scripts', 'scpui_system_core.lua'), 'utf8');
	// An RC's features are badged with the release it leads up to
	const m = core.match(/local version = "(\d+\.\d+\.\d+)[^"]*"/);
	if (!m) {
		console.error('Could not find `local version = "X.Y.Z"` in scpui_system_core.lua');
		process.exit(1);
	}
	version = m[1];
}
if (!/^\d+\.\d+\.\d+$/.test(version)) {
	console.error(`"${version}" isn't an X.Y.Z version`);
	process.exit(1);
}

const parts = v => v.split('.').map(Number);
const compare = (a, b) => {
	const [x, y] = [parts(a), parts(b)];
	for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] - y[i];
	return 0;
};
const badge = v => `![SCPUI ${v}](${BASE}scpui-${v}.svg)`;

// Same look as the existing badges: 93px wide for 11 characters, 7px per character more or less
function svg(v) {
	const label = `SCPUI ${v}`;
	const width = 93 + 7 * (label.length - 11);
	return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="20" role="img" aria-label="${label}">
<title>${label}</title>
<rect x="0.5" y="0.5" width="${width - 1}" height="19" rx="3" fill="#10283a" stroke="#3fa9f5"/>
<text x="8" y="14" fill="#dff2ff" font-family="Verdana,DejaVu Sans,sans-serif" font-size="11" font-weight="bold" textLength="${width - 16}" lengthAdjust="spacingAndGlyphs">${label}</text>
</svg>
`;
}

const svgPath = path.join(badges, `scpui-${version}.svg`);
if (!fs.existsSync(svgPath)) {
	fs.writeFileSync(svgPath, svg(version));
	console.log(`Created wiki/images/badges/scpui-${version}.svg`);
}

// The legend is the one line in Tables.md that lists every version badge; keep it in version order
const lines = fs.readFileSync(legendPage, 'utf8').split('\n');
const i = lines.findIndex(l => (l.match(BADGE_RE) || []).length > 1);
if (i === -1) {
	console.error("wiki/Tables.md: couldn't find the badge legend line");
	process.exit(1);
}
const versions = [...lines[i].matchAll(BADGE_RE)].map(m => m[1]);
if (!versions.includes(version)) {
	lines[i] = [...versions, version].sort(compare).map(badge).join(' ') + (lines[i].endsWith('\r') ? '\r' : '');
	fs.writeFileSync(legendPage, lines.join('\n'));
	console.log(`Added SCPUI ${version} to the legend in wiki/Tables.md`);
}

console.log(`\nBadge markdown:\n${badge(version)}`);
