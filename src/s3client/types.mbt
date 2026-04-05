///|
pub struct S3Config {
  endpoint : String
  bucket : String
  region : String
  access_key_id : String
  secret_access_key : String
}

///|
pub struct S3Client {
  config : S3Config
  priv mut client : @http.Client?
}

///|
pub fn S3Client::new(config : S3Config) -> S3Client {
  { config, client: None }
}

///|
pub struct S3Object {
  pub key : String
  pub size : Int64
} derive(Show, Eq)
