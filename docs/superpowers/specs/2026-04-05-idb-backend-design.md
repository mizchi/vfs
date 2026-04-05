# IndexedDB Backend for VFS

## Overview

Add an IndexedDB-backed filesystem to mizchi/vfs. Wraps MemoryFs for fast in-memory operations, persists via IDB snapshot flush/hydrate.

## Architecture

```
IndexedDbFs
  inner: MemoryFs        — all read/write ops delegated
  dirty: Bool            — set true on any write
  db_name: String        — IDB database name
  write_count: Int       — auto-flush counter
  auto_flush_threshold: Int — flush every N writes (0=disabled)
```

## Traits Implemented

- FileSystem — delegate to inner + mark dirty
- ReadableFileSystem — delegate to inner (no dirty change)
- Snapshottable — delegate to inner
- Flushable — flush: export snapshot → IDB save, dirty flag

## JS FFI (2 functions)

```js
// Save snapshot to IDB
async function idb_save(dbName, snapshot) {
  const db = await openDB(dbName);
  const tx = db.transaction("snapshots", "readwrite");
  tx.objectStore("snapshots").put(snapshot, "repo");
}

// Load snapshot from IDB
async function idb_load(dbName) -> Snapshot | null {
  const db = await openDB(dbName);
  const tx = db.transaction("snapshots", "readonly");
  return tx.objectStore("snapshots").get("repo");
}
```

## File Layout

```
src/idb/
  moon.pkg
  idb.mbt          — IndexedDbFs struct + trait impls
  js_ffi.mbt       — idb_save_ffi, idb_load_ffi (JS target)
  wasm_ffi.mbt     — stubs (abort)
  idb_test.mbt     — unit tests (MemoryFs delegation only)
```

## Benchmark

Node.js script testing MemoryFs vs IndexedDbFs:
- write 1000 files
- read 1000 files
- flush to IDB
- hydrate from IDB
