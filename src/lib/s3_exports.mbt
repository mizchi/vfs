// JS API exports for S3Fs.

///|
pub fn create_s3_client(
  endpoint : String,
  bucket : String,
  region : String,
  access_key_id : String,
  secret_access_key : String,
) -> @s3client.S3Client {
  @s3client.S3Client::new(
    @s3client.S3Config::new(
      endpoint~,
      bucket~,
      region~,
      access_key_id~,
      secret_access_key~,
    ),
  )
}

///|
pub fn create_s3fs(client : @s3client.S3Client, prefix : String) -> @s3fs.S3Fs {
  @s3fs.S3Fs::new(client, prefix~)
}

///|
pub async fn s3_mkdir_p(
  fs : @s3fs.S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.mkdir_p(path)
}

///|
pub async fn s3_write_file(
  fs : @s3fs.S3Fs,
  path : String,
  content : Bytes,
) -> Unit raise @vfs.VfsError {
  fs.write_file(path, content)
}

///|
pub async fn s3_read_file(
  fs : @s3fs.S3Fs,
  path : String,
) -> Bytes raise @vfs.VfsError {
  fs.read_file(path)
}

///|
pub async fn s3_remove_file(
  fs : @s3fs.S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_file(path)
}

///|
pub async fn s3_remove_dir(
  fs : @s3fs.S3Fs,
  path : String,
) -> Unit raise @vfs.VfsError {
  fs.remove_dir(path)
}

///|
pub async fn s3_readdir(
  fs : @s3fs.S3Fs,
  path : String,
) -> Array[String] raise @vfs.VfsError {
  fs.readdir(path)
}

///|
pub async fn s3_is_dir(fs : @s3fs.S3Fs, path : String) -> Bool {
  fs.is_dir(path)
}

///|
pub async fn s3_is_file(fs : @s3fs.S3Fs, path : String) -> Bool {
  fs.is_file(path)
}
