// Runs integration_test/perf_baseline_test.dart on the connected phone
// (pointed at the EMULATOR SUITE) and appends its rows, plus one median row
// per scenario, to perf-tests/results/baseline-reads.csv.
//
//   node perf-tests/collect.js --label baseline --host 192.168.1.219 [--device "SM G973N"]
//     [--matches 400] [--runs 1] [--scenarios cold_open,pull_to_refresh,profile_save]
//
// --host is the PC's LAN IP the phone uses to reach the emulators.

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => {
    if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1]]);
    return acc;
  }, []),
);
const label = args.label || 'baseline';
const host = args.host;
const device = args.device || 'SM G973N';
// Optional trial-run subsets, passed straight to the harness.
const extra = [
  args.matches && `--dart-define=PERF_MATCHES=${args.matches}`,
  args.runs && `--dart-define=PERF_RUNS=${args.runs}`,
  args.scenarios && `--dart-define=PERF_SCENARIOS=${args.scenarios}`,
].filter(Boolean);
if (!host) {
  console.error('Usage: node perf-tests/collect.js --label <name> --host <PC LAN IP> [--device <id>]');
  process.exit(1);
}

const out = path.join(__dirname, 'results', 'baseline-reads.csv');
const HEADER =
  'label,scenario,matches,run,reads,cache_reads,writes,est_rule_reads,top_read_tags,recorded_at';

const rows = [];
const child = spawn(
  'flutter',
  [
    'test', 'integration_test/perf_baseline_test.dart',
    '-d', device,
    '--dart-define=USE_EMULATOR=true',
    `--dart-define=EMULATOR_HOST=${host}`,
    `--dart-define=PERF_LABEL=${label}`,
    ...extra,
  ],
  { cwd: path.join(__dirname, '..'), shell: true },
);

function onData(buf) {
  const text = buf.toString();
  process.stdout.write(text);
  for (const line of text.split(/\r?\n/)) {
    const at = line.indexOf('PERFCSV,');
    if (at >= 0) rows.push(line.slice(at + 'PERFCSV,'.length).trim());
  }
}
child.stdout.on('data', onData);
child.stderr.on('data', onData);

child.on('close', (code) => {
  if (rows.length === 0) {
    console.error(`\nNo PERFCSV rows captured (flutter exited ${code}). Nothing written.`);
    process.exit(1);
  }
  const now = new Date().toISOString();
  const median = (xs) => {
    const s = [...xs].sort((a, b) => a - b);
    return s[Math.floor(s.length / 2)];
  };
  const groups = new Map();
  for (const r of rows) {
    const [lab, scenario, matches, , reads, cache, writes, est] = r.split(',');
    const key = `${lab},${scenario},${matches}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push([+reads, +cache, +writes, +est]);
  }
  const medians = [...groups.entries()].map(([key, xs]) =>
    [key, 'median', ...[0, 1, 2, 3].map((i) => median(xs.map((x) => x[i]))), ''].join(','),
  );

  fs.mkdirSync(path.dirname(out), { recursive: true });
  const fresh = !fs.existsSync(out);
  // Every row has the 9 fields before recorded_at (top_read_tags may be
  // empty and never contains commas).
  const lines = [...rows, ...medians].map((r) => `${r},${now}`);
  fs.appendFileSync(out, (fresh ? HEADER + '\n' : '') + lines.join('\n') + '\n');
  console.log(`\nAppended ${rows.length} runs + ${medians.length} medians to ${out}`);
  process.exit(code === 0 ? 0 : 1);
});
