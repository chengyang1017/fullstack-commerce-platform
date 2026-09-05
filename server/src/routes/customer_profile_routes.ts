import {
  Router,
  type NextFunction,
  type Request,
  type Response,
} from "express";
import multer from "multer";

import { AppError } from "../lib/app_error.ts";
import { prisma } from "../lib/prisma.ts";
import {
  deleteStoredAvatar,
  readStoredAvatar,
  uploadAvatar,
} from "../lib/avatar_storage.ts";

export const customerProfileRouter = Router();
export const customerAvatarAssetRouter = Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024,
  },
});

function avatarUploadMiddleware(
  request: Request,
  response: Response,
  next: NextFunction,
): void {
  upload.single("avatar")(
    request,
    response,
    (error) => {
      if (!error) {
        next();
        return;
      }

      if (error instanceof multer.MulterError) {
        if (error.code === "LIMIT_FILE_SIZE") {
          next(
            new AppError(
              413,
              "头像不能超过 5 MB",
              "AVATAR_TOO_LARGE",
            ),
          );
          return;
        }

        next(
          new AppError(
            400,
            "头像上传失败",
            "AVATAR_UPLOAD_FAILED",
          ),
        );
        return;
      }

      next(error);
    },
  );
}

customerProfileRouter.get(
  "/",
  async (
    _request: Request,
    response: Response,
  ) => {
    const customer = response.locals.customer as {
      id: string;
    };

    const user = await prisma.user.findUnique({
      where: {
        id: customer.id,
      },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
      },
    });

    if (!user) {
      throw new AppError(
        404,
        "用户不存在",
        "CUSTOMER_NOT_FOUND",
      );
    }

    response.json({
      success: true,
      user,
    });
  },
);

customerProfileRouter.post(
  "/avatar",
  avatarUploadMiddleware,
  async (
    request: Request,
    response: Response,
  ) => {
    const customer = response.locals.customer as {
      id: string;
    };

    if (!request.file) {
      throw new AppError(
        400,
        "请选择头像图片",
        "AVATAR_REQUIRED",
      );
    }

    const contentType = detectAvatarContentType(
      request.file.buffer,
    );

    if (!contentType) {
      throw new AppError(
        400,
        "仅支持 JPG、PNG 或 WebP 图片",
        "INVALID_AVATAR_TYPE",
      );
    }

    const previousUser = await prisma.user.findUnique({
      where: {
        id: customer.id,
      },
      select: {
        avatarUrl: true,
      },
    });

    if (!previousUser) {
      throw new AppError(
        404,
        "用户不存在",
        "CUSTOMER_NOT_FOUND",
      );
    }

    const nextAvatarUrl = await uploadAvatar(
      request.file.buffer,
      contentType,
    );

    try {
      const user = await prisma.user.update({
        where: {
          id: customer.id,
        },
        data: {
          avatarUrl: nextAvatarUrl,
        },
        select: {
          id: true,
          email: true,
          name: true,
          avatarUrl: true,
        },
      });

      await deleteStoredAvatar(previousUser.avatarUrl);

      response.json({
        success: true,
        user,
      });
    } catch (error) {
      await deleteStoredAvatar(nextAvatarUrl);
      throw error;
    }
  },
);

customerProfileRouter.delete(
  "/avatar",
  async (
    _request: Request,
    response: Response,
  ) => {
    const customer = response.locals.customer as {
      id: string;
    };

    const previousUser = await prisma.user.findUnique({
      where: {
        id: customer.id,
      },
      select: {
        avatarUrl: true,
      },
    });

    if (!previousUser) {
      throw new AppError(
        404,
        "用户不存在",
        "CUSTOMER_NOT_FOUND",
      );
    }

    const user = await prisma.user.update({
      where: {
        id: customer.id,
      },
      data: {
        avatarUrl: null,
      },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
      },
    });

    await deleteStoredAvatar(previousUser.avatarUrl);

    response.json({
      success: true,
      user,
    });
  },
);

customerAvatarAssetRouter.get(
  "/:fileName",
  async (
    request: Request,
    response: Response,
  ) => {
    const rawFileName = request.params.fileName;
    const fileName = Array.isArray(rawFileName)
      ? rawFileName[0]
      : rawFileName;

    if (!fileName) {
      response.status(404).json({
        success: false,
        message: "头像不存在",
      });
      return;
    }

    const avatar = await readStoredAvatar(fileName);

    if (!avatar) {
      response.status(404).json({
        success: false,
        message: "头像不存在",
      });
      return;
    }

    response.setHeader(
      "Content-Type",
      avatar.contentType,
    );
    response.setHeader(
      "Cache-Control",
      "public, max-age=86400",
    );
    response.send(avatar.bytes);
  },
);

function detectAvatarContentType(
  bytes: Buffer,
): string | null {
  if (
    bytes.length >= 3 &&
    bytes[0] === 0xff &&
    bytes[1] === 0xd8 &&
    bytes[2] === 0xff
  ) {
    return "image/jpeg";
  }

  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return "image/png";
  }

  if (
    bytes.length >= 12 &&
    bytes.toString("ascii", 0, 4) === "RIFF" &&
    bytes.toString("ascii", 8, 12) === "WEBP"
  ) {
    return "image/webp";
  }

  return null;
}
