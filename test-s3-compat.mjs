// S3 compatibility test for RustFS, Cloudflare R2, MinIO, etc.
//
// Usage:
//   node test-s3-compat.mjs                          # default: rustfs preset
//   node test-s3-compat.mjs rustfs                   # named preset
//   node test-s3-compat.mjs r2                       # R2 preset (needs env vars)
//
// Environment variables (override preset values):
//   S3_ENDPOINT          - e.g. http://localhost:9000
//   S3_REGION            - e.g. us-east-1, auto
//   S3_BUCKET            - e.g. test-vfs
//   S3_ACCESS_KEY_ID     - access key
//   S3_SECRET_ACCESS_KEY - secret key
//   S3_FORCE_PATH_STYLE  - "true" for path-style (default for non-AWS)

import {
  S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand,
  DeleteObjectsCommand, ListObjectsV2Command, HeadObjectCommand,
  CreateBucketCommand, CopyObjectCommand,
} from '@aws-sdk/client-s3';

const PRESETS = {
  rustfs: {
    endpoint: 'http://localhost:9000',
    region: 'us-east-1',
    bucket: 'test-vfs',
    accessKeyId: 'rustfsadmin',
    secretAccessKey: 'rustfsadmin',
    forcePathStyle: true,
  },
  r2: {
    endpoint: process.env.R2_ENDPOINT || 'https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com',
    region: 'auto',
    bucket: process.env.R2_BUCKET || 'test-vfs',
    accessKeyId: process.env.R2_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY || '',
    forcePathStyle: false,
  },
  minio: {
    endpoint: 'http://localhost:9000',
    region: 'us-east-1',
    bucket: 'test-vfs',
    accessKeyId: 'minioadmin',
    secretAccessKey: 'minioadmin',
    forcePathStyle: true,
  },
};

// Resolve config: preset + env overrides
const presetName = process.argv[2] || 'rustfs';
const preset = PRESETS[presetName] || {};
const config = {
  endpoint:        process.env.S3_ENDPOINT          || preset.endpoint        || 'http://localhost:9000',
  region:          process.env.S3_REGION             || preset.region          || 'us-east-1',
  bucket:          process.env.S3_BUCKET             || preset.bucket          || 'test-vfs',
  accessKeyId:     process.env.S3_ACCESS_KEY_ID      || preset.accessKeyId     || '',
  secretAccessKey: process.env.S3_SECRET_ACCESS_KEY  || preset.secretAccessKey || '',
  forcePathStyle:  (process.env.S3_FORCE_PATH_STYLE ?? String(preset.forcePathStyle ?? true)) === 'true',
};

if (!config.accessKeyId || !config.secretAccessKey) {
  console.error('Missing credentials. Set S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY, or use a preset.');
  process.exit(1);
}

console.log(`\n=== S3 Compatibility Test: ${presetName} ===`);
console.log(`  Endpoint:   ${config.endpoint}`);
console.log(`  Region:     ${config.region}`);
console.log(`  Bucket:     ${config.bucket}`);
console.log(`  PathStyle:  ${config.forcePathStyle}\n`);

const client = new S3Client({
  endpoint: config.endpoint,
  region: config.region,
  credentials: { accessKeyId: config.accessKeyId, secretAccessKey: config.secretAccessKey },
  forcePathStyle: config.forcePathStyle,
});

let passed = 0;
let failed = 0;

async function test(name, fn) {
  try {
    await fn();
    console.log(`  \u2713 ${name}`);
    passed++;
  } catch (e) {
    console.log(`  \u2717 ${name}: ${e.message}`);
    failed++;
  }
}

function assert(condition, msg) {
  if (!condition) throw new Error(msg);
}

const Bucket = config.bucket;

try {
  // --- Setup ---
  try {
    await client.send(new CreateBucketCommand({ Bucket }));
    console.log(`Created bucket: ${Bucket}`);
  } catch (e) {
    if (![409, 200].includes(e.$metadata?.httpStatusCode) &&
        !['BucketAlreadyOwnedByYou', 'BucketAlreadyExists'].includes(e.name)) {
      console.log(`Bucket: ${e.name} — continuing`);
    }
  }

  // === PUT ===
  console.log('\n--- PUT Object ---');
  await test('put simple file', async () => {
    await client.send(new PutObjectCommand({ Bucket, Key: 'hello.txt', Body: Buffer.from('Hello, S3!') }));
  });

  await test('put nested path', async () => {
    await client.send(new PutObjectCommand({ Bucket, Key: 'dir/nested/file.txt', Body: Buffer.from('nested content') }));
  });

  await test('put directory marker (0-byte trailing /)', async () => {
    await client.send(new PutObjectCommand({ Bucket, Key: 'dir/', Body: Buffer.alloc(0) }));
    await client.send(new PutObjectCommand({ Bucket, Key: 'dir/nested/', Body: Buffer.alloc(0) }));
  });

  await test('put binary data', async () => {
    const bin = Buffer.from([0x00, 0x01, 0xff, 0xfe, 0x80]);
    await client.send(new PutObjectCommand({ Bucket, Key: 'binary.dat', Body: bin }));
  });

  // === GET ===
  console.log('\n--- GET Object ---');
  await test('get simple file', async () => {
    const res = await client.send(new GetObjectCommand({ Bucket, Key: 'hello.txt' }));
    const body = await res.Body.transformToString();
    assert(body === 'Hello, S3!', `Expected "Hello, S3!" got "${body}"`);
  });

  await test('get nested file', async () => {
    const res = await client.send(new GetObjectCommand({ Bucket, Key: 'dir/nested/file.txt' }));
    const body = await res.Body.transformToString();
    assert(body === 'nested content', `Expected "nested content" got "${body}"`);
  });

  await test('get binary data preserves bytes', async () => {
    const res = await client.send(new GetObjectCommand({ Bucket, Key: 'binary.dat' }));
    const buf = Buffer.from(await res.Body.transformToByteArray());
    assert(buf.length === 5, `Expected 5 bytes, got ${buf.length}`);
    assert(buf[0] === 0x00 && buf[2] === 0xff, 'Binary content mismatch');
  });

  await test('get non-existent file throws', async () => {
    try {
      await client.send(new GetObjectCommand({ Bucket, Key: 'nope.txt' }));
      throw new Error('Should have thrown');
    } catch (e) {
      assert(e.name === 'NoSuchKey' || e.$metadata?.httpStatusCode === 404,
        `Expected NoSuchKey/404, got ${e.name}`);
    }
  });

  // === HEAD ===
  console.log('\n--- HEAD Object ---');
  await test('head existing file', async () => {
    const res = await client.send(new HeadObjectCommand({ Bucket, Key: 'hello.txt' }));
    assert(res.ContentLength === 10, `Expected length 10, got ${res.ContentLength}`);
  });

  await test('head non-existent returns 404', async () => {
    try {
      await client.send(new HeadObjectCommand({ Bucket, Key: 'nope.txt' }));
      throw new Error('Should have thrown');
    } catch (e) {
      assert(e.name === 'NotFound' || e.$metadata?.httpStatusCode === 404,
        `Expected 404, got ${e.name}`);
    }
  });

  await test('head directory marker', async () => {
    const res = await client.send(new HeadObjectCommand({ Bucket, Key: 'dir/nested/' }));
    assert(res.ContentLength === 0, `Expected length 0, got ${res.ContentLength}`);
  });

  // === COPY ===
  console.log('\n--- COPY Object ---');
  await test('copy object', async () => {
    await client.send(new CopyObjectCommand({
      Bucket,
      Key: 'hello-copy.txt',
      CopySource: `${Bucket}/hello.txt`,
    }));
    const res = await client.send(new GetObjectCommand({ Bucket, Key: 'hello-copy.txt' }));
    const body = await res.Body.transformToString();
    assert(body === 'Hello, S3!', `Copy content mismatch: "${body}"`);
  });

  // === LIST ===
  console.log('\n--- LIST Objects ---');
  await test('list all objects', async () => {
    const res = await client.send(new ListObjectsV2Command({ Bucket }));
    assert(res.Contents.length >= 5, `Expected >=5 objects, got ${res.Contents.length}`);
  });

  await test('list with prefix', async () => {
    const res = await client.send(new ListObjectsV2Command({ Bucket, Prefix: 'dir/' }));
    const keys = res.Contents.map(c => c.Key);
    assert(keys.includes('dir/nested/file.txt'), `Missing dir/nested/file.txt`);
  });

  await test('list with delimiter (immediate children)', async () => {
    const res = await client.send(new ListObjectsV2Command({ Bucket, Prefix: 'dir/', Delimiter: '/' }));
    const prefixes = (res.CommonPrefixes || []).map(p => p.Prefix);
    assert(prefixes.includes('dir/nested/'), `Expected dir/nested/ in CommonPrefixes, got ${prefixes}`);
  });

  await test('list with MaxKeys pagination', async () => {
    const res = await client.send(new ListObjectsV2Command({ Bucket, MaxKeys: 2 }));
    assert(res.Contents.length <= 2, `Expected <=2 objects, got ${res.Contents.length}`);
    assert(res.IsTruncated === true, 'Expected IsTruncated=true');
    assert(res.NextContinuationToken, 'Expected NextContinuationToken');
    // Fetch next page
    const res2 = await client.send(new ListObjectsV2Command({
      Bucket, MaxKeys: 2, ContinuationToken: res.NextContinuationToken,
    }));
    assert(res2.Contents.length >= 1, 'Expected at least 1 object on page 2');
  });

  // === DELETE (single) ===
  console.log('\n--- DELETE Object ---');
  await test('delete single file', async () => {
    await client.send(new DeleteObjectCommand({ Bucket, Key: 'hello-copy.txt' }));
    try {
      await client.send(new HeadObjectCommand({ Bucket, Key: 'hello-copy.txt' }));
      throw new Error('Should be deleted');
    } catch (e) {
      assert(e.name === 'NotFound' || e.$metadata?.httpStatusCode === 404, `Expected 404`);
    }
  });

  // === DELETE Objects (batch) ===
  console.log('\n--- DELETE Objects (batch) ---');
  await test('batch delete multiple objects', async () => {
    // Create some objects to batch-delete
    await client.send(new PutObjectCommand({ Bucket, Key: 'batch/a.txt', Body: Buffer.from('a') }));
    await client.send(new PutObjectCommand({ Bucket, Key: 'batch/b.txt', Body: Buffer.from('b') }));
    await client.send(new PutObjectCommand({ Bucket, Key: 'batch/c.txt', Body: Buffer.from('c') }));

    await client.send(new DeleteObjectsCommand({
      Bucket,
      Delete: {
        Objects: [{ Key: 'batch/a.txt' }, { Key: 'batch/b.txt' }, { Key: 'batch/c.txt' }],
      },
    }));

    // Verify all deleted
    for (const k of ['batch/a.txt', 'batch/b.txt', 'batch/c.txt']) {
      try {
        await client.send(new HeadObjectCommand({ Bucket, Key: k }));
        throw new Error(`${k} should be deleted`);
      } catch (e) {
        assert(e.name === 'NotFound' || e.$metadata?.httpStatusCode === 404, `Expected 404 for ${k}`);
      }
    }
  });

  // === Cleanup ===
  console.log('\n--- Cleanup ---');
  const remaining = await client.send(new ListObjectsV2Command({ Bucket }));
  const objects = remaining.Contents || [];
  if (objects.length > 0) {
    await client.send(new DeleteObjectsCommand({
      Bucket,
      Delete: { Objects: objects.map(o => ({ Key: o.Key })) },
    }));
  }
  console.log(`  Cleaned up ${objects.length} objects`);

} finally {
  client.destroy();
}

console.log(`\n=== Results: ${passed} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
