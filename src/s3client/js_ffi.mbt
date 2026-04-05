///|
extern "js" fn sha256_hex_ffi(data : Bytes) -> @js_async.Promise[String] =
  #| async (data) => {
  #|   const buf = await crypto.subtle.digest('SHA-256', data instanceof Uint8Array ? data : new Uint8Array(data));
  #|   return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
  #| }

///|
extern "js" fn hmac_sha256_ffi(key : Bytes, data : Bytes) -> @js_async.Promise[Bytes] =
  #| async (key, data) => {
  #|   const k = key instanceof Uint8Array ? key : new Uint8Array(key);
  #|   const d = data instanceof Uint8Array ? data : new Uint8Array(data);
  #|   const cryptoKey = await crypto.subtle.importKey('raw', k, { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  #|   const sig = await crypto.subtle.sign('HMAC', cryptoKey, d);
  #|   return new Uint8Array(sig);
  #| }

///|
extern "js" fn amz_date_now_ffi() -> String =
  #| () => {
  #|   const d = new Date();
  #|   return d.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  #| }
