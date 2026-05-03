#include "image_encode.h"
#include <hilog/log.h>
#include <cstdio>
#include <cstring>

#define LOG_TAG "ImageEncode"

// 简单的 BMP 编码示例
napi_value EncodeImage(napi_env env, napi_value callback_info) {
  size_t argc = 3;
  napi_value args[3];
  napi_get_cb_info(env, callback_info, &argc, args, nullptr, nullptr);
  
  if (argc < 2) {
    napi_throw_error(env, nullptr, "Missing input or output path argument");
    return nullptr;
  }
  
  // 获取输入文件路径
  char input_path[1024];
  size_t input_len;
  napi_get_value_string_utf8(env, args[0], input_path, sizeof(input_path), &input_len);
  
  // 获取输出文件路径
  char output_path[1024];
  size_t output_len;
  napi_get_value_string_utf8(env, args[1], output_path, sizeof(output_path), &output_len);
  
  OH_LOG_INFO(LOG_APP, "Encoding image: %{public}s -> %{public}s", input_path, output_path);
  
  // 读取输入文件
  FILE* input_file = fopen(input_path, "rb");
  if (!input_file) {
    napi_throw_error(env, nullptr, "Failed to open input file");
    return nullptr;
  }
  
  // 获取文件大小
  fseek(input_file, 0, SEEK_END);
  long file_size = ftell(input_file);
  fseek(input_file, 0, SEEK_SET);
  
  // 读取文件内容
  unsigned char* buffer = (unsigned char*)malloc(file_size);
  fread(buffer, 1, file_size, input_file);
  fclose(input_file);
  
  // 写入输出文件（简化版 - 直接复制）
  FILE* output_file = fopen(output_path, "wb");
  if (!output_file) {
    free(buffer);
    napi_throw_error(env, nullptr, "Failed to open output file");
    return nullptr;
  }
  
  fwrite(buffer, 1, file_size, output_file);
  fclose(output_file);
  free(buffer);
  
  // 创建返回对象
  napi_value result;
  napi_create_object(env, &result);
  
  napi_value success_val;
  napi_get_boolean(env, true, &success_val);
  napi_set_named_property(env, result, "success", success_val);
  
  OH_LOG_INFO(LOG_APP, "Image encoded successfully");
  
  return result;
}
