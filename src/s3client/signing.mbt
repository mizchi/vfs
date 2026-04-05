///|
pub async fn sha256_hex(data : Bytes) -> String {
  sha256_hex_ffi(data).wait()
}

///|
pub async fn hmac_sha256(key : Bytes, data : Bytes) -> Bytes {
  hmac_sha256_ffi(key, data).wait()
}

///|
fn date_stamp(date : String) -> String {
  date.substring(end=8)
}

///|
async fn derive_signing_key(
  secret : String,
  date_stamp : String,
  region : String,
  service : String,
) -> Bytes {
  let k_secret = @utf8.encode("AWS4" + secret)
  let k_date = hmac_sha256(k_secret, @utf8.encode(date_stamp))
  let k_region = hmac_sha256(k_date, @utf8.encode(region))
  let k_service = hmac_sha256(k_region, @utf8.encode(service))
  hmac_sha256(k_service, @utf8.encode("aws4_request"))
}

///|
fn bytes_to_hex(b : Bytes) -> String {
  let sb = StringBuilder::new()
  let hex_chars = "0123456789abcdef"
  for i in 0..<b.length() {
    let byte_val = b[i].to_int()
    sb.write_char(hex_chars.get_char(byte_val.lsr(4).land(0xf)).unwrap())
    sb.write_char(hex_chars.get_char(byte_val.land(0xf)).unwrap())
  }
  sb.to_string()
}

///|
pub async fn sign_request(
  config : S3Config,
  method : String,
  path : String,
  query : String,
  headers : Array[(String, String)],
  payload_hash : String,
  amz_date : String,
) -> String {
  let ds = date_stamp(amz_date)
  let credential_scope = "\{ds}/\{config.region}/s3/aws4_request"
  let sorted_headers = headers.copy()
  sorted_headers.sort_by(fn(a, b) { a.0.compare(b.0) })
  let canonical_headers = StringBuilder::new()
  let signed_header_names : Array[String] = []
  for pair in sorted_headers {
    let (k, v) = pair
    canonical_headers.write_string("\{k}:\{v}\n")
    signed_header_names.push(k)
  }
  let signed_headers = signed_header_names.join(";")
  let canonical_request = [
    method, path, query, canonical_headers.to_string(), signed_headers, payload_hash,
  ].join("\n")
  let canonical_request_hash = sha256_hex(@utf8.encode(canonical_request))
  let string_to_sign = [
    "AWS4-HMAC-SHA256", amz_date, credential_scope, canonical_request_hash,
  ].join("\n")
  let signing_key = derive_signing_key(config.secret_access_key, ds, config.region, "s3")
  let signature_bytes = hmac_sha256(signing_key, @utf8.encode(string_to_sign))
  let signature = bytes_to_hex(signature_bytes)
  "AWS4-HMAC-SHA256 Credential=\{config.access_key_id}/\{credential_scope}, SignedHeaders=\{signed_headers}, Signature=\{signature}"
}
