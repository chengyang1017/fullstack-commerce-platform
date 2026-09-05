import {
  randomUUID,
} from "node:crypto";

import {
  basename,
} from "node:path";

import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";

export const avatarPublicPrefix =
  "/uploads/avatars";

interface AvatarStorageConfig {
  endpoint: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
  region: string;
}

interface StoredAvatar {
  bytes: Buffer;
  contentType: string;
}

export async function uploadAvatar(
  buffer: Buffer,
  contentType: string,
): Promise<string> {
  const {
    client,
    bucket,
  } = createStorageClient();

  const extension =
    extensionForContentType(
      contentType,
    );

  const fileName =
    `${randomUUID()}${extension}`;

  const key =
    `avatars/${fileName}`;

  await client.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType:
        contentType,
      CacheControl:
        "public, max-age=86400",
    }),
  );

  return (
    `${avatarPublicPrefix}/` +
    fileName
  );
}

export async function
deleteStoredAvatar(
  avatarUrl:
    string | null,
): Promise<void> {
  if (
    !avatarUrl ||
    !avatarUrl.startsWith(
      `${avatarPublicPrefix}/`,
    )
  ) {
    return;
  }

  const fileName =
    basename(
      avatarUrl,
    );

  if (
    !isSafeFileName(
      fileName,
    )
  ) {
    return;
  }

  const {
    client,
    bucket,
  } = createStorageClient();

  await client.send(
    new DeleteObjectCommand({
      Bucket: bucket,
      Key:
        `avatars/${fileName}`,
    }),
  );
}

export async function
readStoredAvatar(
  fileName: string,
): Promise<StoredAvatar | null> {
  if (
    !isSafeFileName(
      fileName,
    )
  ) {
    return null;
  }

  const {
    client,
    bucket,
  } = createStorageClient();

  try {
    const result =
      await client.send(
        new GetObjectCommand({
          Bucket: bucket,
          Key:
            `avatars/${fileName}`,
        }),
      );

    if (!result.Body) {
      return null;
    }

    const bytes =
      await result.Body
        .transformToByteArray();

    return {
      bytes:
        Buffer.from(
          bytes,
        ),

      contentType:
        result.ContentType ??
        "application/octet-stream",
    };
  } catch (error) {
    if (
      isNotFoundError(
        error,
      )
    ) {
      return null;
    }

    throw error;
  }
}

function createStorageClient(): {
  client: S3Client;
  bucket: string;
} {
  const config =
    readStorageConfig();

  const client =
    new S3Client({
      endpoint:
        config.endpoint,

      region:
        config.region,

      credentials: {
        accessKeyId:
          config.accessKeyId,

        secretAccessKey:
          config.secretAccessKey,
      },
    });

  return {
    client,
    bucket:
      config.bucket,
  };
}

function readStorageConfig():
  AvatarStorageConfig {
  return {
    endpoint:
      requireEnvironmentVariable(
        "S3_ENDPOINT",
      ),

    accessKeyId:
      requireEnvironmentVariable(
        "S3_ACCESS_KEY_ID",
      ),

    secretAccessKey:
      requireEnvironmentVariable(
        "S3_SECRET_ACCESS_KEY",
      ),

    bucket:
      requireEnvironmentVariable(
        "S3_BUCKET",
      ),

    region:
      process.env.S3_REGION ??
      "auto",
  };
}

function requireEnvironmentVariable(
  name: string,
): string {
  const value =
    process.env[name];

  if (
    !value ||
    value.trim().length === 0
  ) {
    throw new Error(
      `Missing environment variable: ${name}`,
    );
  }

  return value.trim();
}

function extensionForContentType(
  contentType: string,
): string {
  return switchContentType(
    contentType,
  );
}

function switchContentType(
  contentType: string,
): string {
  switch (contentType) {
    case "image/jpeg":
      return ".jpg";

    case "image/png":
      return ".png";

    case "image/webp":
      return ".webp";

    default:
      throw new Error(
        `Unsupported avatar type: ${contentType}`,
      );
  }
}

function isSafeFileName(
  fileName: string,
): boolean {
  return (
    /^[a-zA-Z0-9._-]+$/
      .test(
        fileName,
      )
  );
}

function isNotFoundError(
  error: unknown,
): boolean {
  if (
    typeof error !==
      "object" ||
    error === null
  ) {
    return false;
  }

  if (
    "name" in error &&
    (
      error as {
        name?: unknown;
      }
    ).name ===
      "NoSuchKey"
  ) {
    return true;
  }

  if (
    "$metadata" in error
  ) {
    const metadata =
      (
        error as {
          $metadata?: {
            httpStatusCode?:
              number;
          };
        }
      ).$metadata;

    return (
      metadata
        ?.httpStatusCode ===
      404
    );
  }

  return false;
}