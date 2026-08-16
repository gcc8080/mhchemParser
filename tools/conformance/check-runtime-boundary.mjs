#!/usr/bin/env node

import { readdir, readFile } from 'node:fs/promises';
import { resolve } from 'node:path';

import { repoRoot } from './baseline.mjs';

const packageRoot = resolve(repoRoot, 'flutter/mhchemParser');
const pubspec = await readFile(resolve(packageRoot, 'pubspec.yaml'), 'utf8');
const lines = pubspec.split(/\r?\n/u);
const dependenciesIndex = lines.findIndex((line) => line === 'dependencies:');

if (dependenciesIndex >= 0) {
  const runtimeEntries = [];
  for (const line of lines.slice(dependenciesIndex + 1)) {
    if (line.length > 0 && !/^\s/u.test(line)) {
      break;
    }
    if (/^  [a-zA-Z0-9_-]+:/u.test(line)) {
      runtimeEntries.push(line.trim());
    }
  }
  if (runtimeEntries.length > 0) {
    throw new Error(
      `Runtime dependencies must remain empty, found: ${runtimeEntries.join(', ')}`,
    );
  }
}

const forbiddenImports = [
  'dart:html',
  'dart:js',
  'dart:js_interop',
  'package:flutter/',
  'webview',
  'javascript',
];

async function dartFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await dartFiles(path)));
    } else if (entry.isFile() && entry.name.endsWith('.dart')) {
      files.push(path);
    }
  }
  return files;
}

for (const path of await dartFiles(resolve(packageRoot, 'lib'))) {
  const source = (await readFile(path, 'utf8')).toLowerCase();
  for (const forbidden of forbiddenImports) {
    if (source.includes(forbidden)) {
      throw new Error(
        `Forbidden runtime import or dependency marker "${forbidden}" in ${path}.`,
      );
    }
  }
}

console.log(
  'Verified pure-Dart runtime boundary: no runtime packages, Flutter, WebView, or JavaScript imports.',
);
