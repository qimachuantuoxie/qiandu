#include "image_decode.h"
#include <hilog/log.h>
#include <cstdio>
#include <cstring>

#define LOG_TAG "ImageDecode"

// 简单的 BMP 解码示例
napi_value DecodeImage(napi_env env, napi_value callback_info) {
  size_t argc = 2;
  napi_value args[2];
  napi_get_cb_info(env, callback_info, &argc, args, nullptr, nullptr);
  
  if (argc < 1) {
    napi_throw_error(env, nullptr, "Missing file path argument");
    return nullptr;
  }
  
  // 获取文件路径
  char path[1024];
  size_t path_len;
  napi_get_value_string_utf8(env, args[0], path, sizeof(path), &path_len);
  
  OH_LOG_INFO(LOG_APP, "Decoding image: %{public}s", path);
  
  // 读取文件
  FILE* file = fopen(path, "rb");
  if (!file) {
    napi_throw_error(env, nullptr, "Failed to open file");
    return nullptr;
  }
  
  // 获取文件大小
  fseek(file, 0, SEEK_END);
  long file_size = ftell(file);
  fseek(file, 0, SEEK_SET);
  
  // 读取文件内容
  unsigned char* buffer = (unsigned char*)malloc(file_size);
  fread(buffer, 1, file_size, file);
  fclose(file);
  
  // 解析图片信息（简化版 - 仅支持BMP示例）
  int width = 0, height = 0;
  
  // BMP 文件头解析
  if (buffer[0] == 'B' && buffer[1] == 'M') {
    width = *(int*)(buffer + 18);
    height = *(int*)(buffer + 22);
  }
  // PNG 文件头解析
  else if (buffer[0] == 0x89 && buffer[1] == 'P' && buffer[2] == 'N' && buffer[3] == 'G') {
    width = (buffer[16] << 8) | buffer[17];
    height = (buffer[20] << 8) | buffer[21];
  }
  // JPEG 文件头解析
  else if (buffer[0] == 0xFF && buffer[1] == 0xD8) {
    // 简化的JPEG解析
    for (int i = 2; i < file_size - 1; i++) {
      if (buffer[i] == 0xFF && buffer[i+1] >= 0xC0 && buffer[i+1] <= 0xC3) {
        height = (buffer[i+5] << 8) | buffer[i+6];
        width = (buffer[i+7] << 8) | buffer[i+8];
        break;
      }
    }
  }
  
  free(buffer);
  
  // 创建返回对象
  napi_value result;
  napi_create_object(env, &result);
  
  napi_value width_val, height_val, size_val;
  napi_create_int32(env, width, &width_val);
  napi_create_int32(env, height, &height_val);
  napi_create_int64(env, file_size, &size_val);
  
  napi_set_named_property(env, result, "width", width_val);
  napi_set_named_property(env, result, "height", height_val);
  napi_set_named_property(env, result, "size", size_val);
  
  OH_LOG_INFO(LOG_APP, "Image decoded: %{public}dx%{public}d, %{public}ld bytes", width, height, file_size);
  
  return result;
}

napi_value DecodeImageInfo(napi_env env, napi_value callback_info) {
  // 复用 DecodeImage 逻辑
  return DecodeImage(env, callback_info);
}
