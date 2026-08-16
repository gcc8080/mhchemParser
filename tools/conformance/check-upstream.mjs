#!/usr/bin/env node

import {
  auditedFiles,
  upstreamCommit,
  upstreamVersion,
  verifyAuditedFiles,
} from './baseline.mjs';

await verifyAuditedFiles();

console.log(
  `Verified ${Object.keys(auditedFiles).length} audited files for ` +
    `mhchemParser ${upstreamVersion} at ${upstreamCommit}.`,
);
