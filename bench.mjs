// VFS Benchmark: MemoryFs vs IndexedDbFs vs SqliteFs
// Usage: node bench.mjs
import 'fake-indexeddb/auto';

const mod = await import('./_build/js/debug/build/src/lib/lib.js');

function unwrap(result) {
  if (result && typeof result === 'object' && '_0' in result) return result._0;
  return result;
}

function bench(name, fn) {
  const start = performance.now();
  fn();
  const elapsed = performance.now() - start;
  console.log(`  ${name}: ${elapsed.toFixed(2)} ms`);
  return elapsed;
}

const FILE_COUNT = 1000;
const FILE_SIZE = 1024;
const content = new Uint8Array(FILE_SIZE);
for (let i = 0; i < FILE_SIZE; i++) content[i] = i & 0xff;

console.log(`\n=== VFS Benchmark ===`);
console.log(`Files: ${FILE_COUNT}, Size: ${FILE_SIZE} bytes each\n`);

const results = {};

function runSuite(name, ops) {
  console.log(`--- ${name} ---`);
  const times = {};

  times.write = bench(`write ${FILE_COUNT} files`, () => {
    for (let i = 0; i < FILE_COUNT; i++) {
      unwrap(ops.writeFile(`/files/file-${i}.dat`, content));
    }
  });

  times.read = bench(`read ${FILE_COUNT} files`, () => {
    for (let i = 0; i < FILE_COUNT; i++) {
      unwrap(ops.readFile(`/files/file-${i}.dat`));
    }
  });

  times.readdir = bench(`readdir (${FILE_COUNT} entries)`, () => {
    unwrap(ops.readdir('/files'));
  });

  times.isFile = bench(`is_file × ${FILE_COUNT}`, () => {
    for (let i = 0; i < FILE_COUNT; i++) {
      ops.isFile(`/files/file-${i}.dat`);
    }
  });

  results[name] = times;
  console.log('');
}

// --- MemoryFs ---
const memFs = mod.createMemoryFs();
runSuite('MemoryFs', {
  writeFile: (p, c) => mod.writeFile(memFs, p, c),
  readFile: (p) => mod.readFile(memFs, p),
  readdir: (p) => mod.readdir(memFs, p),
  isFile: (p) => mod.isFile(memFs, p),
});

// --- IndexedDbFs ---
const idbFs = mod.createIdbFs();
runSuite('IndexedDbFs', {
  writeFile: (p, c) => mod.idbWriteFile(idbFs, p, c),
  readFile: (p) => mod.idbReadFile(idbFs, p),
  readdir: (p) => mod.idbReaddir(idbFs, p),
  isFile: (p) => mod.idbIsFile(idbFs, p),
});

// --- SqliteFs ---
try {
  const sqlFs = mod.createSqliteFsMemory();
  runSuite('SqliteFs (:memory:)', {
    writeFile: (p, c) => mod.sqliteWriteFile(sqlFs, p, c),
    readFile: (p) => mod.sqliteReadFile(sqlFs, p),
    readdir: (p) => mod.sqliteReaddir(sqlFs, p),
    isFile: (p) => mod.sqliteIsFile(sqlFs, p),
  });
} catch (e) {
  console.log(`--- SqliteFs (:memory:) ---`);
  console.log(`  skipped: ${e.message}\n`);
}

// --- Summary ---
console.log('=== Summary (ms) ===');
console.log('| Backend | write | read | readdir | is_file |');
console.log('|---|---|---|---|---|');
for (const [name, t] of Object.entries(results)) {
  console.log(`| ${name} | ${t.write.toFixed(1)} | ${t.read.toFixed(1)} | ${t.readdir.toFixed(2)} | ${t.isFile.toFixed(1)} |`);
}
console.log('');
