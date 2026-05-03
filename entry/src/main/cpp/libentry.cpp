// NAPI 桥接入口
// 将 C++ 功能暴露给 ArkTS
#include "napi/native_api.h"
#include "NativePdfParser.h"
#include "NativeZipUtils.h"

// DJVU 和 CHM 解析器
struct DjvuInfo {
    char title[256];
    char author[256];
    int pageCount;
    int width;
    int height;
    int fileSize;
};

struct ChmInfo {
    char title[256];
    char author[256];
    int pageCount;
    int fileCount;
    int fileSize;
    char encoding[64];
};

extern "C" int ParseDjvuInfo(const char* filePath, DjvuInfo* info);
extern "C" int ParseChmInfo(const char* filePath, ChmInfo* info);

// 桥接函数：获取 PDF 信息
static napi_value GetPdfInfo(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    char path[512];
    size_t len;
    napi_get_value_string_utf8(env, args[0], path, sizeof(path), &len);

    NativePdfInfo pdfInfo = ParsePdfInfo(path);

    napi_value result;
    napi_create_object(env, &result);

    napi_value titleVal;
    napi_create_string_utf8(env, pdfInfo.title, NAPI_AUTO_LENGTH, &titleVal);
    napi_set_named_property(env, result, "title", titleVal);

    napi_value pageVal;
    napi_create_int32(env, pdfInfo.pageCount, &pageVal);
    napi_set_named_property(env, result, "pageCount", pageVal);

    return result;
}

// 桥接函数：获取 ZIP 文件数量
static napi_value GetZipFileCount(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    char path[512];
    size_t len;
    napi_get_value_string_utf8(env, args[0], path, sizeof(path), &len);

    int count = ParseZipFileCount(path);

    napi_value result;
    napi_create_int32(env, count, &result);
    return result;
}

// 桥接函数：获取 DJVU 信息
static napi_value GetDjvuInfo(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    char path[512];
    size_t len;
    napi_get_value_string_utf8(env, args[0], path, sizeof(path), &len);

    DjvuInfo djvuInfo;
    int result_code = ParseDjvuInfo(path, &djvuInfo);

    napi_value result;
    napi_create_object(env, &result);

    napi_value titleVal;
    napi_create_string_utf8(env, djvuInfo.title, NAPI_AUTO_LENGTH, &titleVal);
    napi_set_named_property(env, result, "title", titleVal);

    napi_value authorVal;
    napi_create_string_utf8(env, djvuInfo.author, NAPI_AUTO_LENGTH, &authorVal);
    napi_set_named_property(env, result, "author", authorVal);

    napi_value pageVal;
    napi_create_int32(env, djvuInfo.pageCount, &pageVal);
    napi_set_named_property(env, result, "pageCount", pageVal);

    napi_value successVal;
    napi_create_int32(env, result_code == 0 ? 1 : 0, &successVal);
    napi_set_named_property(env, result, "success", successVal);

    return result;
}

// 桥接函数：获取 CHM 的信息
static napi_value GetChmInfo(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    char path[512];
    size_t len;
    napi_get_value_string_utf8(env, args[0], path, sizeof(path), &len);

    ChmInfo chmInfo;
    int result_code = ParseChmInfo(path, &chmInfo);

    napi_value result;
    napi_create_object(env, &result);

    napi_value titleVal;
    napi_create_string_utf8(env, chmInfo.title, NAPI_AUTO_LENGTH, &titleVal);
    napi_set_named_property(env, result, "title", titleVal);

    napi_value authorVal;
    napi_create_string_utf8(env, chmInfo.author, NAPI_AUTO_LENGTH, &authorVal);
    napi_set_named_property(env, result, "author", authorVal);

    napi_value pageVal;
    napi_create_int32(env, chmInfo.pageCount, &pageVal);
    napi_set_named_property(env, result, "pageCount", pageVal);

    napi_value fileCountVal;
    napi_create_int32(env, chmInfo.fileCount, &fileCountVal);
    napi_set_named_property(env, result, "fileCount", fileCountVal);

    napi_value successVal;
    napi_create_int32(env, result_code == 0 ? 1 : 0, &successVal);
    napi_set_named_property(env, result, "success", successVal);

    return result;
}

// 模块初始化
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "getPdfInfo", nullptr, GetPdfInfo, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getZipFileCount", nullptr, GetZipFileCount, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getDjvuInfo", nullptr, GetDjvuInfo, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getChmInfo", nullptr, GetChmInfo, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

NAPI_MODULE(entry, Init)
