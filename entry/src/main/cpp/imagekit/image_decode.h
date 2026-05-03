#ifndef IMAGE_DECODE_H
#define IMAGE_DECODE_H

#include <napi/native.h>

// 解码图片
napi_value DecodeImage(napi_env env, napi_value callback_info);

// 获取图片信息
napi_value DecodeImageInfo(napi_env env, napi_value callback_info);

#endif // IMAGE_DECODE_H
