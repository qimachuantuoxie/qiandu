#ifndef IMAGEKIT_NAPI_H
#define IMAGEKIT_NAPI_H

#include <napi/native.h>

// 导出所有函数
napi_value ImageKitInit(napi_env env, napi_value exports);

#endif // IMAGEKIT_NAPI_H
