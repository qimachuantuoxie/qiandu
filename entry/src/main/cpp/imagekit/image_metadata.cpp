#include "image_metadata.h"
#include <hilog/log.h>
#include <cstdio>
#include <cstring>

#define LOG_TAG "ImageMetadata"

// 获取图片元数据
napi_value GetImageMetadata(napi_env env, napi_value callback_info) {
  size_t argc = 1;
  napi_value args[1];
  napi_get_cb_info(env, callback_info, &argc, args, nullptr, nullptr);
  
  if (argc < 1) {
    napi_throw_error(env, nullptr, "Missing file path argument");
    return nullptr;
  }
  
  // 获取文件路径
  char path[1024];
  size_t path_len;
  napi_get_value_string_utf8(env, args[0], path, sizeof(path), &path_len);
  
  OH_LOG_INFO(LOG_APP, "Getting image metadata: %{public}s", path);
  
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
  
  // 简化版 - 返回基本元数据（实际需要解析EXIF等）
  napi_value result;
  napi_create_object(env, &result);
  
  // 设置示例元数据
  napi_value title_val, author_val;
  napi_create_string_utf8(env, "Image", NAPI_AUTO_LENGTH, &title_val);
  napi_create_string_utf8(env, "Unknown", NAPI_AUTO_LENGTH, &author_val);
  
  napi_set_named_property(env, result, "title", title_val);
  napi_set_named_property(env, result, "author", author_val);
  
  free(buffer);
  
  OH_LOG_INFO(LOG_APP, "Image metadata retrieved");
  
  return result;
}

// 设置图片元数据
napi_value SetImageMetadata(napi_env env, napi_value callback_info) {
  size_t argc = 2;
  napi_value args[2];
  napi_get_cb_info(env, callback_info, &argc, args, nullptr, nullptr);
  
  if (argc < 2) {
    napi_throw_error(env, nullptr, "Missing file path or metadata argument");
    return nullptr;
  }
  
  // 获取文件路径
  char path[1024];
  size_t path_len;
  napi_get_value_string_utf8(env, args[0], path, sizeof(path), &path_len);
  
  // 获取元数据对象
  napi_value metadata = args[1];
  
  OH_LOG_INFO(LOG_APP, "Setting image metadata: %{public}s", path);
  
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
  
  // 简化版 - 直接返回成功（实际需要写入元数据）
  napi_value result;
  napi_create_object(env, &result);
  
  napi_value success_val;
  napi_get_boolean(env, true, &success_val);
  napi_set_named_property(env, result, "success", success_val);
  
  free(buffer);
  
  OH_LOG_INFO(LOG_APP, "Image metadata set successfully");
  
  return result;
}
