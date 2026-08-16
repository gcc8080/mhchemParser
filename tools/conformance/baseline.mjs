import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const upstreamVersion = '4.2.2';
export const upstreamCommit = 'acaf5adb97a08deb234e0a8d62c807c17ee650d6';

export const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
export const corpusPath =
  'flutter/mhchemParser/test/fixtures/mhchem_parser_4_2_2.json';

export const auditedFiles = Object.freeze({
  'js/mhchemParser/LICENSE.txt':
    'e1be8c4e92fe92593d010397067705f351324c4478a7fa4d598e7a4734946728',
  'js/mhchemParser/package.json':
    '4628eca7a4f3f5d21ad4e5307e6481ef45df4f18c10018fd0839ec3b441329ef',
  'js/mhchemParser/src/mhchemParser.ts':
    '193b84cc5a18d44df2d4ebb2281b94cf183a316193ba4d1407d1b6dba15c5502',
  'js/mhchemParser/dist/mhchemParser.js':
    '95f75dfe279f408de267d8af81573aed41fe52db650a96a56230f3d0c01184f4',
  'js/mhchemParser/test/test-dist.html':
    '3dab404cfa1eee1779bb3ba3fb88817da134607bc02312a5d58a0185d77452bd',
});

export const expectedCounts = Object.freeze({
  tex: 1,
  ce: 95,
  pu: 21,
});

export async function sha256(relativePath) {
  const data = await readFile(resolve(repoRoot, relativePath));
  return createHash('sha256').update(data).digest('hex');
}

export async function verifyAuditedFiles() {
  const failures = [];
  for (const [relativePath, expected] of Object.entries(auditedFiles)) {
    const actual = await sha256(relativePath);
    if (actual !== expected) {
      failures.push({ relativePath, expected, actual });
    }
  }

  if (failures.length > 0) {
    const details = failures
      .map(
        ({ relativePath, expected, actual }) =>
          `${relativePath}: expected ${expected}, got ${actual}`,
      )
      .join('\n');
    throw new Error(`Upstream baseline integrity check failed:\n${details}`);
  }
}
