#include "imagekit_napi.h"
#include "image_decode.h"
#include "image_encode.h"
#include "image_resize.h"
#include "image_rotate.h"
#include "image_crop.h"
#include "image_metadata.h"
#include <hilog/log.h>

#define LOG_TAG "ImageKitNAPI"

// 模块初始化
napi_value ImageKitInit(napi_env env, napi_value exports) {
  napi_property_descriptor desc[] = {
    // 解码
    DECLARE_NAPI_FUNCTION("decodeImage", DecodeImage),
    DECLARE_NAPI_FUNCTION("decodeImageInfo", DecodeImageInfo),
    
    // 编码
    DECLARE_NAPI_FUNCTION("encodeImage", EncodeImage),
    
    // 缩放
    DECLARE_NAPI_FUNCTION("resizeImage", ResizeImage),
    
    // 旋转
    DECLARE_NAPI_FUNCTION("rotateImage", RotateImage),
    
    // 裁剪
    DECLARE_NAPI_FUNCTION("cropImage", CropImage),
    
    // 元数据
    DECLARE_NAPI_FUNCTION("getImageMetadata", GetImageMetadata),
    DECLARE_NAPI_FUNCTION("setImageMetadata", SetImageMetadata)
  };
  
  NAPI_CALL(env, napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc));
  
  OH_LOG_INFO(LOG_APP, "ImageKit module initialized");
  return exports;
}

// 模块注册
static napi_module imagekit_module = {
  .nm_version = 1,
  .nm_flags = 0,
  .nm_filename = nullptr,
  .nm_register_func = ImageKitInit,
  .nm_modname = "imagekit",
  .nm_priv = nullptr,
  .reserved = {0}
};

extern "C" __attribute__((constructor)) void RegisterImageKitModule() {
  napi_module_register(&imagekit_module);
}
