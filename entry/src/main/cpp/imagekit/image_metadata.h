#ifndef IMAGE_METADATA_H
#define IMAGE_METADATA_H

#include <napi/native.h>

// 获取图片元数据
napi_value GetImageMetadata(napi_env env, napi_value callback_info);

// 设置图片元数据
napi_value SetImageMetadata(napi_env env, napi_value callback_info);

#endif // IMAGE_METADATA_H
