import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const checker = fileURLToPath(new URL('./check_flutter_coverage.mjs', import.meta.url));

function run(t, content, threshold = '50') {
  const temp = mkdtempSync(join(tmpdir(), 'warmmemo-coverage-'));
  t.after(() => rmSync(temp, { recursive: true }));
  const report = join(temp, 'lcov.info');
  if (content !== undefined) writeFileSync(report, content);
  const result = spawnSync(process.execPath, [checker, report, threshold], {
    cwd: temp,
    encoding: 'utf8',
  });
  assert.ifError(result.error);
  return { status: result.status, output: result.stdout + result.stderr };
}

const record = (path, ...lines) => [`SF:${path}`, ...lines, 'end_of_record', ''].join('\n');
const mixed = record('lib/main.dart', 'DA:1,1', 'DA:2,0', 'LF:2', 'LH:1');

test('passes full coverage across multiple production files', (t) => {
  const report = record('lib/main.dart', 'DA:1,5') + record('lib/nested/a.dart', 'DA:2,1,abc123');
  const result = run(t, report, '100');
  assert.equal(result.status, 0);
  assert.match(result.output, /100% \(2\/2\).*Required: 100%.*PASS/);
});

test('prints partial coverage and passes exactly at the threshold', (t) => {
  const result = run(t, mixed, '50.0000');
  assert.equal(result.status, 0);
  assert.match(result.output, /50% \(1\/2\).*Required: 50%.*PASS/);
});

test('fails one configured unit above measured coverage', (t) => {
  const result = run(t, mixed, '50.0001');
  assert.equal(result.status, 1);
  assert.match(result.output, /50% \(1\/2\).*Required: 50\.0001%.*FAIL/);
});

test('does not round a failing result up to the threshold', (t) => {
  const report = record('lib/main.dart', 'DA:1,1', 'DA:2,1', 'DA:3,0');
  assert.match(run(t, report, '66.6666').output, /66\.6666%.*PASS/);
  const result = run(t, report, '66.6667');
  assert.equal(result.status, 1);
  assert.match(result.output, /66\.6666%.*FAIL/);
});

test('counts zero covered lines and allows an explicit zero threshold', (t) => {
  const report = record('lib/main.dart', 'DA:1,0', 'DA:2,0', 'LF:2', 'LH:0');
  const result = run(t, report, '0');
  assert.equal(result.status, 0);
  assert.match(result.output, /0% \(0\/2\)/);
  assert.equal(run(t, report, '0.0001').status, 1);
});

test('fails for absent, empty, or uninstrumented reports', (t) => {
  const missing = run(t, undefined);
  assert.equal(missing.status, 1);
  assert.match(missing.output, /ENOENT/);
  for (const content of ['', record('lib/main.dart', 'LF:0', 'LH:0')]) {
    const result = run(t, content, '0');
    assert.equal(result.status, 1);
    assert.match(result.output, /no instrumented production Dart lines/);
  }
});

test('rejects bad data, totals, ordering, and incomplete records', (t) => {
  for (const content of [
    'DA:1,1\nend_of_record',
    'SF:lib/main.dart\nDA:1,1',
    record('lib/main.dart', 'DA:0,1'),
    record('lib/main.dart', 'DA:1,-1'),
    record('lib/main.dart', 'DA:1,1', 'LF:2', 'LH:1'),
    record('lib/main.dart', 'DA:1,1', 'LF:1', 'LH:0'),
  ]) {
    const result = run(t, content);
    assert.equal(result.status, 1);
    assert.match(result.output, /Malformed LCOV/);
  }
});

test('deduplicates source and line records, with any hit marking a line covered', (t) => {
  const report = record('lib/main.dart', 'DA:1,0', 'DA:1,1', 'DA:2,0', 'LF:2', 'LH:1')
    + record('./lib\\main.dart', 'DA:2,1', 'DA:3,0');
  const result = run(t, report, '66');
  assert.equal(result.status, 0);
  assert.match(result.output, /66\.6666% \(2\/3\)/);
});

test('excludes outside files and ignores branch and function coverage', (t) => {
  const report = record('test/main_test.dart', 'DA:1,1')
    + record('lib/../test/other.dart', 'DA:1,1')
    + record('lib/a.js', 'DA:1,1')
    + record('lib/a.dart', 'DA:1,0', 'BRDA:1,0,0,9', 'FNDA:8,f');
  const result = run(t, report, '1');
  assert.equal(result.status, 1);
  assert.match(result.output, /0% \(0\/1\)/);
});

test('rejects invalid minimums before reading the report', (t) => {
  for (const threshold of ['', '-1', '100.0001', 'NaN', '1e1', '50.00001']) {
    const result = run(t, mixed, threshold);
    assert.equal(result.status, 1);
    assert.match(result.output, /Minimum coverage/);
  }
});
