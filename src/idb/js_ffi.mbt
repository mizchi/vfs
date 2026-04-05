///|
/// Open (or create) an IndexedDB database with a "snapshots" object store.
/// Returns the snapshot stored under key "repo", or null.
extern "js" fn idb_load_ffi(
  db_name : String,
) -> @js_async.Promise[@vfs.Snapshot?] =
  #| async (dbName) => {
  #|   const req = indexedDB.open(dbName, 1);
  #|   const db = await new Promise((resolve, reject) => {
  #|     req.onupgradeneeded = () => {
  #|       const db = req.result;
  #|       if (!db.objectStoreNames.contains("snapshots")) {
  #|         db.createObjectStore("snapshots");
  #|       }
  #|     };
  #|     req.onsuccess = () => resolve(req.result);
  #|     req.onerror = () => reject(req.error);
  #|   });
  #|   const tx = db.transaction("snapshots", "readonly");
  #|   const store = tx.objectStore("snapshots");
  #|   const result = await new Promise((resolve, reject) => {
  #|     const r = store.get("repo");
  #|     r.onsuccess = () => resolve(r.result ?? null);
  #|     r.onerror = () => reject(r.error);
  #|   });
  #|   db.close();
  #|   return result;
  #| }

///|
/// Save a snapshot to IndexedDB under key "repo".
extern "js" fn idb_save_ffi(
  db_name : String,
  snapshot : @vfs.Snapshot,
) -> @js_async.Promise[Unit] =
  #| async (dbName, snapshot) => {
  #|   const req = indexedDB.open(dbName, 1);
  #|   const db = await new Promise((resolve, reject) => {
  #|     req.onupgradeneeded = () => {
  #|       const db = req.result;
  #|       if (!db.objectStoreNames.contains("snapshots")) {
  #|         db.createObjectStore("snapshots");
  #|       }
  #|     };
  #|     req.onsuccess = () => resolve(req.result);
  #|     req.onerror = () => reject(req.error);
  #|   });
  #|   const tx = db.transaction("snapshots", "readwrite");
  #|   const store = tx.objectStore("snapshots");
  #|   await new Promise((resolve, reject) => {
  #|     const r = store.put(snapshot, "repo");
  #|     r.onsuccess = () => resolve();
  #|     r.onerror = () => reject(r.error);
  #|   });
  #|   db.close();
  #| }
