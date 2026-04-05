///|
fn amz_date_now() -> String {
  amz_date_now_ffi()
}

///|
fn S3Client::signing_path(self : S3Client, key : String) -> String {
  "/\{self.config.bucket}/\{key}"
}

///|
async fn S3Client::ensure_client(self : S3Client) -> @http.Client raise @vfs.VfsError {
  match self.client {
    Some(c) => c
    None => {
      let c = try { @http.Client::new(self.config.endpoint) } catch {
        e => raise @vfs.vfs_error("S3 connection failed: \{e}")
      }
      self.client = Some(c)
      c
    }
  }
}

///|
fn extract_host(url : String) -> String {
  let s = if url is [.. "https://", .. rest] {
    rest.to_string()
  } else if url is [.. "http://", .. rest] {
    rest.to_string()
  } else {
    url
  }
  let idx = string_index_of(s, "/", 0)
  if idx >= 0 { s.substring(end=idx) } else { s }
}

///|
async fn S3Client::signed_headers(
  self : S3Client,
  meth : String,
  key : String,
  query : String,
  payload_hash : String,
) -> Map[String, String] {
  let amz_date = amz_date_now()
  let host = extract_host(self.config.endpoint)
  let headers : Array[(String, String)] = [
    ("host", host),
    ("x-amz-content-sha256", payload_hash),
    ("x-amz-date", amz_date),
  ]
  let auth = sign_request(
    self.config, meth, self.signing_path(key), query, headers, payload_hash, amz_date,
  )
  let result : Map[String, String] = {}
  result["x-amz-content-sha256"] = payload_hash
  result["x-amz-date"] = amz_date
  result["authorization"] = auth
  result
}

///|
let empty_sha256 : String = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

///|
pub async fn S3Client::get_object(self : S3Client, key : String) -> Bytes raise @vfs.VfsError {
  let extra = try { self.signed_headers("GET", key, "", empty_sha256) } catch {
    e => raise @vfs.vfs_error("S3 GET signing failed: \{e}")
  }
  let client = self.ensure_client()
  let response = try { client.get("/\{self.config.bucket}/\{key}", extra_headers=extra) } catch {
    e => raise @vfs.vfs_error("S3 GET request failed: \{e}")
  }
  if response.code != 200 {
    raise @vfs.vfs_error("S3 GET failed: status \{response.code}")
  }
  let data = try { (client : &@io.Reader).read_all() } catch {
    e => raise @vfs.vfs_error("S3 GET read failed: \{e}")
  }
  data.binary()
}

///|
pub async fn S3Client::put_object(self : S3Client, key : String, data : Bytes) -> Unit raise @vfs.VfsError {
  let payload_hash = try { sha256_hex(data) } catch {
    e => raise @vfs.vfs_error("S3 PUT hash failed: \{e}")
  }
  let extra = try { self.signed_headers("PUT", key, "", payload_hash) } catch {
    e => raise @vfs.vfs_error("S3 PUT signing failed: \{e}")
  }
  let client = self.ensure_client()
  let response = try { client.put("/\{self.config.bucket}/\{key}", data, extra_headers=extra) } catch {
    e => raise @vfs.vfs_error("S3 PUT request failed: \{e}")
  }
  if response.code != 200 && response.code != 204 {
    raise @vfs.vfs_error("S3 PUT failed: status \{response.code}")
  }
}

///|
pub async fn S3Client::delete_object(self : S3Client, key : String) -> Unit raise @vfs.VfsError {
  let extra = try { self.signed_headers("DELETE", key, "", empty_sha256) } catch {
    e => raise @vfs.vfs_error("S3 DELETE signing failed: \{e}")
  }
  let client = self.ensure_client()
  try {
    client.request(@http.Delete, "/\{self.config.bucket}/\{key}", extra_headers=extra)
  } catch {
    e => raise @vfs.vfs_error("S3 DELETE request failed: \{e}")
  }
  let response = try { client.end_request() } catch {
    e => raise @vfs.vfs_error("S3 DELETE end_request failed: \{e}")
  }
  if response.code != 204 && response.code != 200 {
    raise @vfs.vfs_error("S3 DELETE failed: status \{response.code}")
  }
}

///|
pub async fn S3Client::list_objects(self : S3Client, prefix : String) -> Array[S3Object] raise @vfs.VfsError {
  let extra = try { self.signed_headers("GET", "", "list-type=2&prefix=\{prefix}", empty_sha256) } catch {
    e => raise @vfs.vfs_error("S3 LIST signing failed: \{e}")
  }
  let client = self.ensure_client()
  let response = try { client.get("/\{self.config.bucket}?list-type=2&prefix=\{prefix}", extra_headers=extra) } catch {
    e => raise @vfs.vfs_error("S3 LIST request failed: \{e}")
  }
  if response.code != 200 {
    raise @vfs.vfs_error("S3 LIST failed: status \{response.code}")
  }
  let body_data = try { (client : &@io.Reader).read_all() } catch {
    e => raise @vfs.vfs_error("S3 LIST read failed: \{e}")
  }
  let xml = try { body_data.text() } catch {
    e => raise @vfs.vfs_error("S3 LIST decode failed: \{e}")
  }
  parse_list_objects_v2(xml)
}

///|
pub async fn S3Client::head_object(self : S3Client, key : String) -> S3Object? raise @vfs.VfsError {
  let extra = try { self.signed_headers("HEAD", key, "", empty_sha256) } catch {
    e => raise @vfs.vfs_error("S3 HEAD signing failed: \{e}")
  }
  let client = self.ensure_client()
  try {
    client.request(@http.Head, "/\{self.config.bucket}/\{key}", extra_headers=extra)
  } catch {
    e => raise @vfs.vfs_error("S3 HEAD request failed: \{e}")
  }
  let response = try { client.end_request() } catch {
    e => raise @vfs.vfs_error("S3 HEAD end_request failed: \{e}")
  }
  if response.code == 404 { return None }
  if response.code != 200 {
    raise @vfs.vfs_error("S3 HEAD failed: status \{response.code}")
  }
  let size : Int64 = match response.headers.get("content-length") {
    Some(s) => try { @strconv.parse_int64(s) } catch { _ => 0L }
    None => 0L
  }
  Some({ key, size })
}
