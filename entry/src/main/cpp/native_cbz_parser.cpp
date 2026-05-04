/**
 * CBZ Parser NAPI 绑定
 * 
 * 提供 CBZ/CBR 漫画文件的解析能力
 */

#include <napi/native_api.h>
#include "cbz_parser.h"
#include <string>
#include <vector>

/**
 * 解析 CBZ 文件信息
 */
static Napi::Value ParseCbzInfoNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "File path required").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    
    CbzInfo cbzInfo;
    int result = ParseCbzInfo(filePath.c_str(), &cbzInfo);
    
    if (result != 0) {
        Napi::Error::New(env, "Failed to parse CBZ file").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    // 创建返回对象
    Napi::Object obj = Napi::Object::New(env);
    obj.Set("title", Napi::String::New(env, cbzInfo.title));
    obj.Set("author", Napi::String::New(env, cbzInfo.author));
    obj.Set("pageCount", Napi::Number::New(env, cbzInfo.pageCount));
    
    return obj;
}

/**
 * 获取 CBZ 页面数量
 */
static Napi::Value GetCbzPageCountNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "File path required").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    
    int pageCount = GetCbzPageCount(filePath.c_str());
    
    if (pageCount < 0) {
        Napi::Error::New(env, "Failed to get page count").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    return Napi::Number::New(env, pageCount);
}

/**
 * 获取 CBZ 页面图片数据
 */
static Napi::Value GetCbzPageImageNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 2 || 
        !info[0].IsString() || 
        !info[1].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    int pageIndex = info[1].As<Napi::Number>().Int32Value();
    
    int imageSize = 0;
    unsigned char* imageData = GetCbzPageImage(filePath.c_str(), pageIndex, &imageSize);
    
    if (!imageData || imageSize <= 0) {
        Napi::Error::New(env, "Failed to get page image").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    // 创建 ArrayBuffer
    Napi::ArrayBuffer buffer = Napi::ArrayBuffer::New(env, imageSize);
    memcpy(buffer.Data(), imageData, imageSize);
    
    delete[] imageData; // 释放 C++ 分配的内存
    
    // 创建 Uint8Array
    Napi::Uint8Array uint8Array = Napi::Uint8Array::New(env, imageSize, buffer, 0);
    
    return uint8Array;
}

/**
 * 获取 CBZ 页面文件名列表
 */
static Napi::Value GetCbzPageFileNamesNapi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "File path required").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string filePath = info[0].As<Napi::String>().Utf8Value();
    
    // 先获取页面数量
    int pageCount = GetCbzPageCount(filePath.c_str());
    
    if (pageCount < 0) {
        Napi::Error::New(env, "Failed to get page count").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    // 分配文件名数组
    char** fileNames = new char*[pageCount];
    for (int i = 0; i < pageCount; ++i) {
        fileNames[i] = nullptr;
    }
    
    int count = GetCbzPageFileNames(filePath.c_str(), fileNames, pageCount);
    
    if (count < 0) {
        // 清理
        for (int i = 0; i < pageCount; ++i) {
            if (fileNames[i]) delete[] fileNames[i];
        }
        delete[] fileNames;
        
        Napi::Error::New(env, "Failed to get file names").ThrowAsJavaScriptException();
        return env.Null();
    }
    
    // 创建 JavaScript 数组
    Napi::Array result = Napi::Array::New(env, count);
    
    for (int i = 0; i < count; ++i) {
        if (fileNames[i]) {
            result.Set(i, Napi::String::New(env, fileNames[i]));
            delete[] fileNames[i]; // 释放每个字符串
        }
    }
    
    delete[] fileNames; // 释放数组
    
    return result;
}

/**
 * 模块初始化
 */
static Napi::Object Init(Napi::Env env, Napi::Object exports) {
    exports.Set("parseCbzInfo", Napi::Function::New(env, ParseCbzInfoNapi));
    exports.Set("getCbzPageCount", Napi::Function::New(env, GetCbzPageCountNapi));
    exports.Set("getCbzPageImage", Napi::Function::New(env, GetCbzPageImageNapi));
    exports.Set("getCbzPageFileNames", Napi::Function::New(env, GetCbzPageFileNamesNapi));
    
    return exports;
}

NODE_API_MODULE(cbz_parser, Init)
