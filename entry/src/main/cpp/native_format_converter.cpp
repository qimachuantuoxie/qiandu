/**
 * Native Format Converter NAPI 绑定
 * 
 * 提供 CHM、DJVU 等格式的解析和转换功能
 */

#include <napi/native_api.h>
#include "chm_parser.h"
#include "djvu_parser.h"
#include <string>
#include <vector>

/**
 * 解析 CHM 文件信息
 */
static Napi::Value ParseChmInfoNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "File path required").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    
    ChmInfo chmInfo;
    int result = ParseChmInfo(filePath.c_str(), &chmInfo);
    
    if (result != 0) {
        Napi::Error::New(env, "Failed to parse CHM file").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    // 创建返回对象
    Napi::Object obj = Napi::Object::New(env);
    obj.Set("title", Napi::String::New(env, chmInfo.title));
    obj.Set("author", Napi::String::New(env, chmInfo.author));
    obj.Set("pageCount", Napi::Number::New(env, chmInfo.pageCount));
    obj.Set("fileCount", Napi::Number::New(env, chmInfo.fileCount));
    obj.Set("encoding", Napi::String::New(env, chmInfo.encoding));
    
    return obj;
}

/**
 * 提取 CHM HTML 内容
 */
static Napi::Value ExtractChmHtmlNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "File path required").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    
    char* html = ExtractChmHtml(filePath.c_str());
    
    if (!html) {
        Napi::Error::New(env, "Failed to extract CHM HTML").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    Napi::String result = Napi::String::New(env, html);
    delete[] html; // 释放 C++ 分配的内存
    
    return result;
}

/**
 * 解析 DJVU 文件信息
 */
static Napi::Value ParseDjvuInfoNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "File path required").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    
    DjvuInfo djvuInfo;
    int result = ParseDjvuInfo(filePath.c_str(), &djvuInfo);
    
    if (result != 0) {
        Napi::Error::New(env, "Failed to parse DJVU file").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    // 创建返回对象
    Napi::Object obj = Napi::Object::New(env);
    obj.Set("title", Napi::String::New(env, djvuInfo.title));
    obj.Set("author", Napi::String::New(env, djvuInfo.author));
    obj.Set("pageCount", Napi::Number::New(env, djvuInfo.pageCount));
    obj.Set("width", Napi::Number::New(env, djvuInfo.width));
    obj.Set("height", Napi::Number::New(env, djvuInfo.height));
    
    return obj;
}

/**
 * 渲染 DJVU 页面为图片
 */
static Napi::Value RenderDjvuPageNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 4 || 
        !info[0].IsString() || 
        !info[1].IsNumber() ||
        !info[2].IsNumber() ||
        !info[3].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    int pageIndex = info[1].As<Napi::Number>().Int32Value();
    int width = info[2].As<Napi::Number>().Int32Value();
    int height = info[3].As<Napi::Number>().Int32Value();
    
    int outWidth = 0;
    int outHeight = 0;
    
    unsigned char* rgba = RenderDjvuPage(
        filePath.c_str(), 
        pageIndex, 
        width, 
        height,
        &outWidth,
        &outHeight
    );
    
    if (!rgba) {
        Napi::Error::New(env, "Failed to render DJVU page").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    // 创建 ArrayBuffer
    size_t bufferSize = outWidth * outHeight * 4; // RGBA
    Napi::ArrayBuffer buffer = Napi::ArrayBuffer::New(env, bufferSize);
    memcpy(buffer.Data(), rgba, bufferSize);
    
    delete[] rgba; // 释放 C++ 分配的内存
    
    // 创建 Uint8Array
    Napi::Uint8Array uint8Array = Napi::Uint8Array::New(env, bufferSize, buffer, 0);
    
    // 返回包含数据和尺寸的对象
    Napi::Object result = Napi::Object::New(env);
    result.Set("data", uint8Array);
    result.Set("width", Napi::Number::New(env, outWidth));
    result.Set("height", Napi::Number::New(env, outHeight));
    
    return result;
}

/**
 * 模块初始化
 */
static Napi::Object Init(Napi::Env env, Napi::Object exports) {
    exports.Set("parseChmInfo", Napi::Function::New(env, ParseChmInfoNapi));
    exports.Set("extractChmHtml", Napi::Function::New(env, ExtractChmHtmlNapi));
    exports.Set("parseDjvuInfo", Napi::Function::New(env, ParseDjvuInfoNapi));
    exports.Set("renderDjvuPage", Napi::Function::New(env, RenderDjvuPageNapi));
    
    return exports;
}

NODE_API_MODULE(format_converter, Init)
