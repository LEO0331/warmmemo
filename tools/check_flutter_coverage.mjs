import { readFileSync } from 'node:fs';
import { relative, resolve, sep } from 'node:path';

const precision = 10_000n;
const percentScale = 100n * precision;

function minimumUnits(input) {
  if (!/^\d{1,3}(?:\.\d{1,4})?$/.test(input)) {
    throw new Error('Minimum coverage must be a number from 0 to 100 with up to four decimals.');
  }
  const [whole, fraction = ''] = input.split('.');
  const units = BigInt(whole) * precision + BigInt(fraction.padEnd(4, '0'));
  if (units > percentScale) throw new Error('Minimum coverage must be at most 100%.');
  return units;
}

function isProductionSource(source) {
  const file = relative(process.cwd(), resolve(source.replaceAll('\\', '/')));
  return file.startsWith(`lib${sep}`) && file.endsWith('.dart');
}

function readLineCoverage(report) {
  const sources = new Map();
  let record;
  let row = 0;
  const invalid = (message) => {
    throw new Error(`Malformed LCOV at line ${row}: ${message}`);
  };

  for (const raw of report.split(/\r?\n/)) {
    row++;
    const line = raw.trim();
    if (line === '') continue;

    if (line.startsWith('TN:') && !record) continue;
    if (line.startsWith('SF:')) {
      const file = line.slice(3).trim();
      if (record || !file) invalid('expected a new, nonempty source path.');
      record = { file, hits: new Map(), totals: new Map() };
      continue;
    }
    if (!record) invalid('expected SF before coverage records.');

    if (line === 'end_of_record') {
      const covered = [...record.hits.values()].filter(Boolean).length;
      for (const [key, actual] of [['LF', record.hits.size], ['LH', covered]]) {
        if (record.totals.has(key) && record.totals.get(key) !== BigInt(actual)) {
          invalid(`${key} does not match the DA line records.`);
        }
      }
      if (isProductionSource(record.file)) {
        const file = resolve(record.file.replaceAll('\\', '/'));
        const hits = sources.get(file) ?? new Map();
        for (const [number, hit] of record.hits) {
          hits.set(number, hit || hits.get(number) === true);
        }
        sources.set(file, hits);
      }
      record = undefined;
      continue;
    }

    const data = /^DA:([1-9]\d*),(\d+)(?:,([^,\s]+))?$/.exec(line);
    if (data) {
      const [, number, count] = data;
      const hit = BigInt(count) > 0n;
      record.hits.set(number, hit || record.hits.get(number) === true);
      continue;
    }
    const total = /^(LF|LH):(\d+)$/.exec(line);
    if (total) {
      const [, key, value] = total;
      if (record.totals.has(key)) invalid(`duplicate ${key} record.`);
      record.totals.set(key, BigInt(value));
      continue;
    }
    // LCOV function and branch data does not contribute to line coverage.
    if (/^(?:FN|FNDA|FNF|FNH|FNL|FNA|BRDA|BRF|BRH):/.test(line)) continue;
    invalid('expected a line, total, function, branch, or record terminator.');
  }

  if (record) invalid('missing end_of_record.');
  let covered = 0;
  let total = 0;
  for (const hits of sources.values()) {
    total += hits.size;
    for (const hit of hits.values()) if (hit) covered++;
  }
  if (total === 0) throw new Error('LCOV has no instrumented production Dart lines under lib/.');
  return { covered, total };
}

function formatPercent(units) {
  const whole = units / precision;
  const fraction = (units % precision).toString().padStart(4, '0').replace(/0+$/, '');
  return fraction ? `${whole}.${fraction}%` : `${whole}%`;
}

try {
  const [file, threshold, ...extra] = process.argv.slice(2);
  if (!file || threshold === undefined || extra.length) {
    throw new Error('Usage: node tools/check_flutter_coverage.mjs <lcov.info> <minimum-percent>');
  }
  const minimum = minimumUnits(threshold);
  const { covered, total } = readLineCoverage(readFileSync(file, 'utf8'));
  const numerator = BigInt(covered) * percentScale;
  const denominator = BigInt(total);
  const passed = numerator >= minimum * denominator;
  console.log(`Flutter line coverage: ${formatPercent(numerator / denominator)} (${covered}/${total}). Required: ${formatPercent(minimum)}. ${passed ? 'PASS' : 'FAIL (below threshold)'}`);
  if (!passed) process.exitCode = 1;
} catch (error) {
  console.error(`Flutter coverage error: ${error.message}`);
  process.exitCode = 1;
}
