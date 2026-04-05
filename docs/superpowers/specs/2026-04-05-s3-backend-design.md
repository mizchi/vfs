# S3 Compatible Backend for VFS

## Overview

Add an S3-compatible storage backend to mizchi/vfs, enabling the virtual filesystem to persist data to S3-compatible services (Cloudflare R2, MinIO, AWS S3) via async operations.

## Target Environments

- **Cloudflare Workers** (R2 bindings / S3-compatible API)
- **WASI** (host-provided HTTP client)

## Design Decisions

- **Async-first**: All existing traits (`FileSystem`, `ReadableFileSystem`, `Snapshottable`, `Flushable`) become async. Breaking change.
- **Architecture A**: Separate S3 protocol layer (`s3client`) from VFS adapter (`s3fs`).
- **Auth via FFI**: SigV4 signing delegated to host (JS `crypto.subtle` / WASI host functions). No pure-MoonBit crypto implementation.

## Breaking Changes

| Change | Impact |
|---|---|
| All trait methods become async | Callers need async context |
| MemoryFs methods become async | JS exports return Promise |
| JS exports return Promise | Existing JS consumers must update |

Version bump: 0.1.0 → 0.2.0

---

## 1. Async Trait Conversion (`types.mbt`)

All trait methods gain the `async` keyword. `MemoryFs` implementations become async (body remains synchronous).

```moonbit
pub(open) trait FileSystem {
  async mkdir_p(Self, String) -> Unit raise VfsError
  async write_file(Self, String, Bytes) -> Unit raise VfsError
  async write_string(Self, String, String) -> Unit raise VfsError
  async remove_file(Self, String) -> Unit raise VfsError
  async remove_dir(Self, String) -> Unit raise VfsError
}

pub(open) trait ReadableFileSystem {
  async read_file(Self, String) -> Bytes raise VfsError
  async readdir(Self, String) -> Array[String] raise VfsError
  async is_dir(Self, String) -> Bool
  async is_file(Self, String) -> Bool
}

pub(open) trait Snapshottable {
  async export_snapshot(Self) -> Snapshot
  async replace_snapshot(Self, Snapshot) -> Unit raise VfsError
}
```

## 2. S3 Client Package (`src/s3client`)

Minimal S3-compatible protocol layer. Handles HTTP requests and response parsing. Does NOT know about VFS paths.

### File Structure

```
src/s3client/
  ├── moon.pkg
  ├── types.mbt        — S3Config, S3Client, S3Object
  ├── operations.mbt   — get_object, put_object, delete_object, list_objects, head_object
  ├── xml.mbt          — Minimal XML parser for ListObjectsV2 response
  ├── js_ffi.mbt       — Workers: fetch + crypto.subtle signing
  └── wasm_ffi.mbt     — WASI: host-provided HTTP/signing functions
```

### Types

```moonbit
pub struct S3Config {
  endpoint : String          // "https://xxx.r2.cloudflarestorage.com"
  bucket : String
  region : String            // "auto" for R2
  access_key_id : String
  secret_access_key : String
}

pub struct S3Client {
  config : S3Config
}

pub struct S3Object {
  key : String
  size : Int64
}
```

### FFI Boundary

```moonbit
// js_ffi.mbt (Workers)
async extern "js" fn http_request(
  method : String, url : String, headers : Array[(String, String)], body : Bytes?
) -> (Int, Bytes)

async extern "js" fn sign_v4(
  method : String, url : String, headers : Array[(String, String)],
  body_hash : String, config : S3Config
) -> Array[(String, String)]
```

### Operations API

```moonbit
pub async fn S3Client::get_object(self, key : String) -> Bytes raise VfsError
pub async fn S3Client::put_object(self, key : String, data : Bytes) -> Unit raise VfsError
pub async fn S3Client::delete_object(self, key : String) -> Unit raise VfsError
pub async fn S3Client::list_objects(self, prefix : String) -> Array[S3Object] raise VfsError
pub async fn S3Client::head_object(self, key : String) -> S3Object? raise VfsError
```

## 3. S3 Filesystem Adapter (`src/s3fs`)

Adapts `S3Client` to implement VFS traits. Handles path-to-key mapping.

### File Structure

```
src/s3fs/
  ├── moon.pkg
  ├── s3fs.mbt          — S3Fs struct + trait implementations
  └── s3fs_test.mbt     — Tests with mock S3Client
```

### Path Mapping

- VFS path `/foo/bar.txt` → S3 key `foo/bar.txt` (strip leading `/`)
- Directories represented as 0-byte objects with trailing `/` (e.g., `foo/bar/`)
- Optional key prefix for namespace isolation (e.g., `vfs/`)

### Type

```moonbit
pub struct S3Fs {
  client : @s3client.S3Client
  prefix : String
}

pub fn S3Fs::new(client : @s3client.S3Client, prefix? : String) -> S3Fs
```

### Operation Mapping

| VFS Operation | S3 Operation |
|---|---|
| `mkdir_p("/a/b")` | `put_object("a/", b"")` + `put_object("a/b/", b"")` |
| `write_file("/a/b.txt", data)` | `put_object("a/b.txt", data)` + ensure parent dirs |
| `read_file("/a/b.txt")` | `get_object("a/b.txt")` |
| `remove_file("/a/b.txt")` | `delete_object("a/b.txt")` |
| `remove_dir("/a")` | `list_objects("a/")` → delete all |
| `readdir("/a")` | `list_objects("a/")` with delimiter `/`, return immediate children |
| `is_file("/a/b.txt")` | `head_object("a/b.txt")` is Some and key doesn't end with `/` |
| `is_dir("/a")` | `head_object("a/")` is Some, or `list_objects("a/")` is non-empty |

### Snapshot

- `export_snapshot`: `list_objects("")` → `get_object` for each key → build `Snapshot`
- `replace_snapshot`: delete all existing → `put_object` for each entry in snapshot

## 4. JS Exports Update (`src/lib`)

- Existing MemoryFs exports become async (return Promise to JS)
- New S3Fs factory and operation exports added:

```moonbit
pub async fn create_s3fs(
  endpoint : String, bucket : String, region : String,
  access_key_id : String, secret_access_key : String,
  prefix? : String
) -> @s3fs.S3Fs

pub async fn s3_read_file(fs : @s3fs.S3Fs, path : String) -> Bytes raise @vfs.VfsError
pub async fn s3_write_file(fs : @s3fs.S3Fs, path : String, content : Bytes) -> Unit raise @vfs.VfsError
// ... other operations follow same pattern
```

## Implementation Order

1. Async-ify `types.mbt` traits
2. Update `MemoryFs` to async, fix tests
3. Implement `src/s3client` (types, FFI, operations, XML parser)
4. Implement `src/s3fs` (adapter + tests)
5. Update `src/lib` exports
6. Version bump to 0.2.0
