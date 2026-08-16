#!/usr/bin/env node

import { createRequire } from 'node:module';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import {
  corpusPath,
  expectedCounts,
  repoRoot,
  verifyAuditedFiles,
} from './baseline.mjs';

await verifyAuditedFiles();

const require = createRequire(import.meta.url);
const { mhchemParser } = require(
  resolve(repoRoot, 'js/mhchemParser/dist/mhchemParser.js'),
);
const corpus = JSON.parse(
  await readFile(resolve(repoRoot, corpusPath), 'utf8'),
);

if (corpus.schemaVersion !== 1 || corpus.counts.total !== 117) {
  throw new Error('Unsupported or incomplete canonical corpus.');
}
for (const [mode, expected] of Object.entries(expectedCounts)) {
  if (corpus.counts[mode] !== expected) {
    throw new Error(
      `Expected ${expected} "${mode}" cases, got ${corpus.counts[mode]}.`,
    );
  }
}

const failures = [];
for (const testCase of corpus.cases) {
  const actual = mhchemParser.toTex(testCase.input, testCase.mode);
  if (actual !== testCase.expected) {
    failures.push({
      id: testCase.id,
      mode: testCase.mode,
      input: testCase.input,
      expected: testCase.expected,
      actual,
    });
  }
}

if (failures.length > 0) {
  const details = failures
    .map(
      ({ id, mode, input, expected, actual }) =>
        `[${id}] mode=${mode} input=${JSON.stringify(input)}\n` +
        `  expected: ${JSON.stringify(expected)}\n` +
        `  actual:   ${JSON.stringify(actual)}`,
    )
    .join('\n');
  throw new Error(`JavaScript oracle failed ${failures.length} cases:\n${details}`);
}

console.log('Verified JavaScript oracle against all 117 canonical cases.');
