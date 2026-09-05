import {
  Router,
  type Request,
  type Response,
  type NextFunction,
} from "express";

import multer from "multer";

import {
  AppError,
} from "../lib/app_error.ts";

import {
  prisma,
} from "../lib/prisma.ts";

import {
  avatarPublicPrefix,
  deleteStoredAvatar,
  readStoredAvatar,
  uploadAvatar,
} from "../lib/avatar_storage.ts";

export const customerProfileRouter =
  Router();

const allowedMimeTypes =
  new Set([
    "image/jpeg",
    "image/png",
    "image/webp",
  ]);

const upload =
  multer({
    storage:
      multer.memoryStorage(),

    limits: {
      fileSize:
        5 * 1024 * 1024,
    },

    fileFilter: (
      _request,
      file,
      callback,
    ) => {
      if (
        !allowedMimeTypes.has(
          file.mimetype,
        )
      ) {
        callback(
          new AppError(
            400,
            "仅支持 JPG、PNG 或 WebP 图片",
            "INVALID_AVATAR_TYPE",
          ),
        );

        return;
      }

      callback(
        null,
        true,
      );
    },
  });

function avatarUploadMiddleware(
  request: Request,
  response: Response,
  next: NextFunction,
): void {
  upload.single(
    "avatar",
  )(
    request,
    response,
    (error) => {
      if (!error) {
        next();
        return;
      }

      if (
        error instanceof
        multer.MulterError
      ) {
        if (
          error.code ===
          "LIMIT_FILE_SIZE"
        ) {
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
    const customer =
      response.locals
        .customer as {
          id: string;
        };

    const user =
      await prisma.user
        .findUnique({
          where: {
            id:
              customer.id,
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
    const customer =
      response.locals
        .customer as {
          id: string;
        };

    if (!request.file) {
      throw new AppError(
        400,
        "请选择头像图片",
        "AVATAR_REQUIRED",
      );
    }

    const previousUser =
      await prisma.user
        .findUnique({
          where: {
            id:
              customer.id,
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

    const nextAvatarUrl =
      await uploadAvatar(
        request.file.buffer,
        request.file.mimetype,
      );

    try {
      const user =
        await prisma.user
          .update({
            where: {
              id:
                customer.id,
            },

            data: {
              avatarUrl:
                nextAvatarUrl,
            },

            select: {
              id: true,
              email: true,
              name: true,
              avatarUrl: true,
            },
          });

      await deleteStoredAvatar(
        previousUser
          .avatarUrl,
      );

      response.json({
        success: true,
        user,
      });
    } catch (error) {
      await deleteStoredAvatar(
        nextAvatarUrl,
      );

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
    const customer =
      response.locals
        .customer as {
          id: string;
        };

    const previousUser =
      await prisma.user
        .findUnique({
          where: {
            id:
              customer.id,
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

    const user =
      await prisma.user
        .update({
          where: {
            id:
              customer.id,
          },

          data: {
            avatarUrl:
              null,
          },

          select: {
            id: true,
            email: true,
            name: true,
            avatarUrl: true,
          },
        });

    await deleteStoredAvatar(
      previousUser
        .avatarUrl,
    );

    response.json({
      success: true,
      user,
    });
  },
);

customerProfileRouter.get(
  "/avatar/:fileName",
  async (
    request: Request,
    response: Response,
  ) => {
    const fileName =
      request.params
        .fileName;

    const avatar =
      await readStoredAvatar(
        fileName,
      );

    if (!avatar) {
      response.status(404)
        .json({
          success: false,
          message:
            "头像不存在",
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

    response.send(
      avatar.bytes,
    );
  },
);