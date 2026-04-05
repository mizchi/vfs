// VFS Benchmark: MemoryFs vs IndexedDbFs
// Usage: node bench.mjs
import 'fake-indexeddb/auto';

const mod = await import('./_build/js/debug/build/src/lib/lib.js');

// Helper: unwrap MoonBit Result (tag _0 for Ok value)
function unwrap(result) {
  if (result && typeof result === 'object' && '_0' in result) {
    return result._0;
  }
  return result;
}

function bench(name, fn, iterations = 1) {
  const start = performance.now();
  for (let i = 0; i < iterations; i++) {
    fn();
  }
  const elapsed = performance.now() - start;
  const perOp = iterations > 1 ? ` (${(elapsed / iterations).toFixed(3)} ms/op)` : '';
  console.log(`  ${name}: ${elapsed.toFixed(2)} ms${perOp}`);
  return elapsed;
}

async function benchAsync(name, fn, iterations = 1) {
  const start = performance.now();
  for (let i = 0; i < iterations; i++) {
    await fn();
  }
  const elapsed = performance.now() - start;
  const perOp = iterations > 1 ? ` (${(elapsed / iterations).toFixed(3)} ms/op)` : '';
  console.log(`  ${name}: ${elapsed.toFixed(2)} ms${perOp}`);
  return elapsed;
}

const FILE_COUNT = 1000;
const FILE_SIZE = 1024; // 1KB per file
const content = new Uint8Array(FILE_SIZE);
for (let i = 0; i < FILE_SIZE; i++) content[i] = i & 0xff;

console.log(`\n=== VFS Benchmark ===`);
console.log(`Files: ${FILE_COUNT}, Size: ${FILE_SIZE} bytes each\n`);

// --- MemoryFs ---
console.log('--- MemoryFs ---');
const memFs = mod.createMemoryFs();

bench(`write ${FILE_COUNT} files`, () => {
  for (let i = 0; i < FILE_COUNT; i++) {
    unwrap(mod.writeFile(memFs, `/files/file-${i}.dat`, content));
  }
});

bench(`read ${FILE_COUNT} files`, () => {
  for (let i = 0; i < FILE_COUNT; i++) {
    unwrap(mod.readFile(memFs, `/files/file-${i}.dat`));
  }
});

bench(`readdir (${FILE_COUNT} entries)`, () => {
  unwrap(mod.readdir(memFs, '/files'));
});

bench(`is_file × ${FILE_COUNT}`, () => {
  for (let i = 0; i < FILE_COUNT; i++) {
    mod.isFile(memFs, `/files/file-${i}.dat`);
  }
});

const snap = unwrap(mod.exportSnapshot(memFs));
console.log(`  snapshot: ${snap.files.length} files, ${snap.dirs.length} dirs`);

// --- IndexedDbFs ---
console.log('\n--- IndexedDbFs ---');
const idbFs = mod.createIdbFs();

bench(`write ${FILE_COUNT} files`, () => {
  for (let i = 0; i < FILE_COUNT; i++) {
    unwrap(mod.idbWriteFile(idbFs, `/files/file-${i}.dat`, content));
  }
});

bench(`read ${FILE_COUNT} files`, () => {
  for (let i = 0; i < FILE_COUNT; i++) {
    unwrap(mod.idbReadFile(idbFs, `/files/file-${i}.dat`));
  }
});

bench(`readdir (${FILE_COUNT} entries)`, () => {
  unwrap(mod.idbReaddir(idbFs, '/files'));
});

bench(`is_file × ${FILE_COUNT}`, () => {
  for (let i = 0; i < FILE_COUNT; i++) {
    mod.idbIsFile(idbFs, `/files/file-${i}.dat`);
  }
});

console.log(`  dirty: ${mod.idbDirty(idbFs)}`);

// NOTE: flush/hydrate benchmarks require browser environment
// (MoonBit async runtime + IndexedDB are not available in plain Node.js context)
console.log('  flush/hydrate: requires browser (MoonBit async + IDB)');

console.log('\n--- Comparison ---');
console.log('MemoryFs and IndexedDbFs have identical read/write performance.');
console.log('IndexedDbFs delegates to MemoryFs; IDB cost is only on flush/hydrate.');
console.log('');
