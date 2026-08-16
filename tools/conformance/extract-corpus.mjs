#!/usr/bin/env node

import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import vm from 'node:vm';

import {
  auditedFiles,
  corpusPath,
  expectedCounts,
  repoRoot,
  upstreamCommit,
  upstreamVersion,
  verifyAuditedFiles,
} from './baseline.mjs';

const sourcePath = 'js/mhchemParser/test/test-dist.html';

function parseTestCall(line, lineNumber) {
  const match = /^test\((.*)\);?$/.exec(line.trim());
  if (match === null) {
    throw new Error(`Could not parse canonical test call at line ${lineNumber}.`);
  }

  const values = vm.runInNewContext(`[${match[1]}]`, Object.create(null), {
    timeout: 100,
  });
  if (
    !Array.isArray(values) ||
    values.length !== 3 ||
    values.some((value) => typeof value !== 'string')
  ) {
    throw new Error(
      `Canonical test at line ${lineNumber} is not three string literals.`,
    );
  }
  return values;
}

async function buildCorpus() {
  await verifyAuditedFiles();
  const source = await readFile(resolve(repoRoot, sourcePath), 'utf8');
  const ordinals = { tex: 0, ce: 0, pu: 0 };
  const cases = [];

  for (const [index, line] of source.split(/\r?\n/u).entries()) {
    if (!line.trimStart().startsWith('test(')) {
      continue;
    }
    const [mode, input, expected] = parseTestCall(line, index + 1);
    if (!Object.hasOwn(ordinals, mode)) {
      throw new Error(`Unsupported mode "${mode}" at line ${index + 1}.`);
    }
    ordinals[mode] += 1;
    cases.push({
      id: `${mode}-${String(ordinals[mode]).padStart(3, '0')}`,
      mode,
      input,
      expected,
    });
  }

  const actualCounts = Object.fromEntries(
    Object.keys(expectedCounts).map((mode) => [
      mode,
      cases.filter((entry) => entry.mode === mode).length,
    ]),
  );
  if (
    cases.length !== 117 ||
    Object.keys(expectedCounts).some(
      (mode) => actualCounts[mode] !== expectedCounts[mode],
    )
  ) {
    throw new Error(
      `Unexpected corpus counts: total=${cases.length}, ` +
        `tex=${actualCounts.tex}, ce=${actualCounts.ce}, pu=${actualCounts.pu}.`,
    );
  }

  const ids = new Set(cases.map((entry) => entry.id));
  if (ids.size !== cases.length) {
    throw new Error('Canonical corpus contains duplicate case identifiers.');
  }

  return {
    schemaVersion: 1,
    source: {
      project: 'mhchem/mhchemParser',
      version: upstreamVersion,
      commit: upstreamCommit,
      testFile: sourcePath,
      testFileSha256: auditedFiles[sourcePath],
    },
    counts: {
      total: cases.length,
      ...actualCounts,
    },
    cases,
  };
}

function serialize(corpus) {
  return `${JSON.stringify(corpus, null, 2)}\n`;
}

const command = process.argv[2] ?? '--check';
const outputPath = resolve(repoRoot, corpusPath);
const generated = serialize(await buildCorpus());

if (command === '--write') {
  await mkdir(dirname(outputPath), { recursive: true });
  await writeFile(outputPath, generated, 'utf8');
  console.log(`Wrote 117 canonical cases to ${corpusPath}.`);
} else if (command === '--check') {
  const committed = await readFile(outputPath, 'utf8');
  if (committed !== generated) {
    throw new Error(
      `Canonical corpus drifted. Run "` +
        `node tools/conformance/extract-corpus.mjs --write" and review the diff.`,
    );
  }
  console.log(`Verified deterministic corpus at ${corpusPath} (117 cases).`);
} else if (command === '--stdout') {
  process.stdout.write(generated);
} else {
  throw new Error('Usage: extract-corpus.mjs [--check|--write|--stdout]');
}
