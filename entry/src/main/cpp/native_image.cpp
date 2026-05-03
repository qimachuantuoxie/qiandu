#include "native_image.h"
#include <hilog/log.h>
#include <cstring>

#undef LOG_TAG
#define LOG_TAG "NativeImage"

#define IMG_LOGI(...) OH_LOG_INFO(LOG::ALOG_APP, __VA_ARGS__)
#define IMG_LOGE(...) OH_LOG_ERROR(LOG::ALOG_APP, __VA_ARGS__)

namespace ImageProcessing {

ImageEngine::ImageEngine() : m_loaded(false), m_width(0), m_height(0), m_channels(4) {
    IMG_LOGI("Image Engine created");
}

ImageEngine::~ImageEngine() {
    release();
}

bool ImageEngine::loadImage(const std::string& imagePath) {
    IMG_LOGI("Loading image: %{public}s", imagePath.c_str());
    
    // In production, use image library (stb_image, libpng, libjpeg)
    // Simulate loading
    m_width = 1920;
    m_height = 1080;
    m_channels = 4;
    m_data.resize(m_width * m_height * m_channels, 255);
    m_loaded = true;
    m_format = "unknown";
    
    return true;
}

bool ImageEngine::loadFromBuffer(const std::vector<uint8_t>& buffer) {
    // Load image from memory buffer
    IMG_LOGI("Loading image from buffer, size: %{public}zu", buffer.size());
    
    m_width = 1920;
    m_height = 1080;
    m_channels = 4;
    m_data = buffer;
    m_loaded = true;
    m_format = "unknown";
    
    return true;
}

void ImageEngine::release() {
    m_data.clear();
    m_loaded = false;
    m_width = 0;
    m_height = 0;
    IMG_LOGI("Image released");
}

ImageInfo ImageEngine::getInfo() {
    ImageInfo info;
    info.width = m_width;
    info.height = m_height;
    info.channels = m_channels;
    info.dataSize = m_data.size();
    return info;
}

std::vector<uint8_t> ImageEngine::resize(int width, int height, const std::string& filter) {
    std::vector<uint8_t> output(width * height * m_channels);
    
    // Bilinear interpolation
    float xRatio = (float)m_width / width;
    float yRatio = (float)m_height / height;
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            float srcX = x * xRatio;
            float srcY = y * yRatio;
            
            int x0 = (int)srcX;
            int y0 = (int)srcY;
            int x1 = std::min(x0 + 1, m_width - 1);
            int y1 = std::min(y0 + 1, m_height - 1);
            
            float xWeight = srcX - x0;
            float yWeight = srcY - y0;
            
            for (int c = 0; c < m_channels; c++) {
                float val = 0;
                val += m_data[y0 * m_width * m_channels + x0 * m_channels + c] * (1 - xWeight) * (1 - yWeight);
                val += m_data[y0 * m_width * m_channels + x1 * m_channels + c] * xWeight * (1 - yWeight);
                val += m_data[y1 * m_width * m_channels + x0 * m_channels + c] * (1 - xWeight) * yWeight;
                val += m_data[y1 * m_width * m_channels + x1 * m_channels + c] * xWeight * yWeight;
                
                output[y * width * m_channels + x * m_channels + c] = (uint8_t)val;
            }
        }
    }
    
    m_width = width;
    m_height = height;
    m_data = output;
    
    IMG_LOGI("Image resized to %{public}d x %{public}d", width, height);
    return output;
}

std::vector<uint8_t> ImageEngine::crop(const ImageRegion& region) {
    std::vector<uint8_t> output(region.width * region.height * m_channels);
    
    for (int y = 0; y < region.height; y++) {
        for (int x = 0; x < region.width; x++) {
            int srcIdx = (region.y + y) * m_width * m_channels + (region.x + x) * m_channels;
            int dstIdx = y * region.width * m_channels + x * m_channels;
            std::copy(m_data.begin() + srcIdx, m_data.begin() + srcIdx + m_channels,
                     output.begin() + dstIdx);
        }
    }
    
    m_width = region.width;
    m_height = region.height;
    m_data = output;
    
    return output;
}

std::vector<uint8_t> ImageEngine::rotate(int angle) {
    std::vector<uint8_t> output;
    
    if (angle == 90 || angle == -270) {
        output.resize(m_height * m_width * m_channels);
        for (int y = 0; y < m_height; y++) {
            for (int x = 0; x < m_width; x++) {
                int srcIdx = y * m_width * m_channels + x * m_channels;
                int dstIdx = x * m_height * m_channels + (m_height - 1 - y) * m_channels;
                std::copy(m_data.begin() + srcIdx, m_data.begin() + srcIdx + m_channels,
                         output.begin() + dstIdx);
            }
        }
        std::swap(m_width, m_height);
    } else if (angle == 180 || angle == -180) {
        output.resize(m_width * m_height * m_channels);
        for (int i = 0; i < m_width * m_height; i++) {
            int srcIdx = i * m_channels;
            int dstIdx = (m_width * m_height - 1 - i) * m_channels;
            std::copy(m_data.begin() + srcIdx, m_data.begin() + srcIdx + m_channels,
                     output.begin() + dstIdx);
        }
    } else if (angle == 270 || angle == -90) {
        output.resize(m_height * m_width * m_channels);
        for (int y = 0; y < m_height; y++) {
            for (int x = 0; x < m_width; x++) {
                int srcIdx = y * m_width * m_channels + x * m_channels;
                int dstIdx = (m_width - 1 - x) * m_height * m_channels + y * m_channels;
                std::copy(m_data.begin() + srcIdx, m_data.begin() + srcIdx + m_channels,
                         output.begin() + dstIdx);
            }
        }
        std::swap(m_width, m_height);
    }
    
    if (!output.empty()) {
        m_data = output;
    }
    
    return output;
}

std::vector<uint8_t> ImageEngine::grayscale() {
    std::vector<uint8_t> output(m_width * m_height * m_channels);
    
    for (int i = 0; i < m_width * m_height; i++) {
        int idx = i * m_channels;
        uint8_t r = m_data[idx];
        uint8_t g = m_data[idx + 1];
        uint8_t b = m_data[idx + 2];
        
        uint8_t gray = (uint8_t)(0.299 * r + 0.587 * g + 0.114 * b);
        
        output[idx] = gray;
        output[idx + 1] = gray;
        output[idx + 2] = gray;
        output[idx + 3] = m_data[idx + 3]; // Keep alpha
    }
    
    m_data = output;
    return output;
}

std::vector<uint8_t> ImageEngine::threshold(int threshold) {
    std::vector<uint8_t> output(m_width * m_height * m_channels);
    
    for (int i = 0; i < m_width * m_height; i++) {
        int idx = i * m_channels;
        uint8_t r = m_data[idx];
        uint8_t g = m_data[idx + 1];
        uint8_t b = m_data[idx + 2];
        
        uint8_t gray = (uint8_t)(0.299 * r + 0.587 * g + 0.114 * b);
        uint8_t val = gray > threshold ? 255 : 0;
        
        output[idx] = val;
        output[idx + 1] = val;
        output[idx + 2] = val;
        output[idx + 3] = m_data[idx + 3];
    }
    
    m_data = output;
    return output;
}

std::vector<uint8_t> ImageEngine::adjustBrightness(float factor) {
    std::vector<uint8_t> output(m_width * m_height * m_channels);
    
    for (size_t i = 0; i < m_data.size(); i += m_channels) {
        for (int c = 0; c < 3; c++) {
            int val = (int)(m_data[i + c] * factor);
            output[i + c] = (uint8_t)std::max(0, std::min(255, val));
        }
        output[i + 3] = m_data[i + 3];
    }
    
    m_data = output;
    return output;
}

std::vector<uint8_t> ImageEngine::adjustContrast(float factor) {
    std::vector<uint8_t> output(m_width * m_height * m_channels);
    
    for (size_t i = 0; i < m_data.size(); i += m_channels) {
        for (int c = 0; c < 3; c++) {
            int val = (int)((m_data[i + c] - 128) * factor + 128);
            output[i + c] = (uint8_t)std::max(0, std::min(255, val));
        }
        output[i + 3] = m_data[i + 3];
    }
    
    m_data = output;
    return output;
}

std::vector<uint8_t> ImageEngine::denoise(int strength) {
    // Simple median filter for denoising
    std::vector<uint8_t> output(m_width * m_height * m_channels);
    
    int half = strength / 2;
    for (int y = half; y < m_height - half; y++) {
        for (int x = half; x < m_width - half; x++) {
            for (int c = 0; c < 3; c++) {
                std::vector<uint8_t> neighbors;
                for (int ky = -half; ky <= half; ky++) {
                    for (int kx = -half; kx <= half; kx++) {
                        neighbors.push_back(m_data[(y + ky) * m_width * m_channels + (x + kx) * m_channels + c]);
                    }
                }
                std::sort(neighbors.begin(), neighbors.end());
                output[y * m_width * m_channels + x * m_channels + c] = neighbors[neighbors.size() / 2];
            }
            output[y * m_width * m_channels + x * m_channels + 3] = m_data[y * m_width * m_channels + x * m_channels + 3];
        }
    }
    
    m_data = output;
    return output;
}

std::vector<uint8_t> ImageEngine::sharpen(float amount) {
    // Simple unsharp mask sharpening
    std::vector<uint8_t> output(m_width * m_height * m_channels);
    
    float kernel[3][3] = {
        {0, -1, 0},
        {-1, 5, -1},
        {0, -1, 0}
    };
    
    for (int y = 1; y < m_height - 1; y++) {
        for (int x = 1; x < m_width - 1; x++) {
            for (int c = 0; c < 3; c++) {
                float val = 0;
                for (int ky = -1; ky <= 1; ky++) {
                    for (int kx = -1; kx <= 1; kx++) {
                        val += m_data[(y + ky) * m_width * m_channels + (x + kx) * m_channels + c] * kernel[ky + 1][kx + 1];
                    }
                }
                output[y * m_width * m_channels + x * m_channels + c] = (uint8_t)std::max(0.0f, std::min(255.0f, val * amount));
            }
            output[y * m_width * m_channels + x * m_channels + 3] = m_data[y * m_width * m_channels + x * m_channels + 3];
        }
    }
    
    m_data = output;
    return output;
}

bool ImageEngine::saveToFile(const std::string& path, const std::string& format, int quality) {
    IMG_LOGI("Saving image to: %{public}s, format: %{public}s", path.c_str(), format.c_str());
    // In production, use libpng/libjpeg to save
    return true;
}

std::string ImageEngine::toBase64(const std::string& format, int quality) {
    return "[BASE64_IMAGE_DATA]";
}

} // namespace ImageProcessing

// NAPI bindings
namespace NativeImage {

static std::shared_ptr<ImageProcessing::ImageEngine> g_imageEngine = nullptr;

Napi::Value LoadImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "Invalid arguments: imagePath required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string imagePath = info[0].As<Napi::String>().Utf8Value();
    
    if (g_imageEngine == nullptr) {
        g_imageEngine = std::make_shared<ImageProcessing::ImageEngine>();
    }
    
    bool success = g_imageEngine->loadImage(imagePath);
    
    Napi::Object result = Napi::Object::New(env);
    result.Set("success", Napi::Boolean::New(env, success));
    
    if (success) {
        auto info = g_imageEngine->getInfo();
        result.Set("width", Napi::Number::New(env, info.width));
        result.Set("height", Napi::Number::New(env, info.height));
        result.Set("channels", Napi::Number::New(env, info.channels));
    }
    
    return result;
}

Napi::Value ReleaseImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (g_imageEngine != nullptr) {
        g_imageEngine->release();
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value GetImageInfo(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    Napi::Object result = Napi::Object::New(env);
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        auto info = g_imageEngine->getInfo();
        result.Set("width", Napi::Number::New(env, info.width));
        result.Set("height", Napi::Number::New(env, info.height));
        result.Set("channels", Napi::Number::New(env, info.channels));
        result.Set("dataSize", Napi::Number::New(env, info.dataSize));
    }
    
    return result;
}

Napi::Value ResizeImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 2 || !info[0].IsNumber() || !info[1].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments: width and height required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    int width = info[0].As<Napi::Number>().Int32Value();
    int height = info[1].As<Napi::Number>().Int32Value();
    std::string filter = info.Length() > 2 && info[2].IsString() ? 
        info[2].As<Napi::String>().Utf8Value() : "bilinear";
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->resize(width, height, filter);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value CropImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 4 || !info[0].IsNumber() || !info[1].IsNumber() || 
        !info[2].IsNumber() || !info[3].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments: x, y, width, height required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    ImageProcessing::ImageRegion region;
    region.x = info[0].As<Napi::Number>().Int32Value();
    region.y = info[1].As<Napi::Number>().Int32Value();
    region.width = info[2].As<Napi::Number>().Int32Value();
    region.height = info[3].As<Napi::Number>().Int32Value();
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->crop(region);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value RotateImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments: angle required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    int angle = info[0].As<Napi::Number>().Int32Value();
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->rotate(angle);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value GrayscaleImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->grayscale();
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value ThresholdImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    int threshold = info.Length() > 0 && info[0].IsNumber() ? 
        info[0].As<Napi::Number>().Int32Value() : 128;
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->threshold(threshold);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value AdjustBrightness(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    float factor = info.Length() > 0 && info[0].IsNumber() ? 
        info[0].As<Napi::Number>().FloatValue() : 1.0f;
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->adjustBrightness(factor);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value AdjustContrast(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    float factor = info.Length() > 0 && info[0].IsNumber() ? 
        info[0].As<Napi::Number>().FloatValue() : 1.0f;
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->adjustContrast(factor);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value DenoiseImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    int strength = info.Length() > 0 && info[0].IsNumber() ? 
        info[0].As<Napi::Number>().Int32Value() : 3;
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->denoise(strength);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value SharpenImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    float amount = info.Length() > 0 && info[0].IsNumber() ? 
        info[0].As<Napi::Number>().FloatValue() : 1.0f;
    
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        g_imageEngine->sharpen(amount);
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value SaveImage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "Invalid arguments: path required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string path = info[0].As<Napi::String>().Utf8Value();
    std::string format = info.Length() > 1 && info[1].IsString() ? 
        info[1].As<Napi::String>().Utf8Value() : "png";
    int quality = info.Length() > 2 && info[2].IsNumber() ? 
        info[2].As<Napi::Number>().Int32Value() : 90;
    
    bool success = false;
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        success = g_imageEngine->saveToFile(path, format, quality);
    }
    
    return Napi::Boolean::New(env, success);
}

Napi::Value ImageToBase64(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    std::string format = info.Length() > 0 && info[0].IsString() ? 
        info[0].As<Napi::String>().Utf8Value() : "png";
    int quality = info.Length() > 1 && info[1].IsNumber() ? 
        info[1].As<Napi::Number>().Int32Value() : 90;
    
    std::string base64 = "";
    if (g_imageEngine != nullptr && g_imageEngine->isLoaded()) {
        base64 = g_imageEngine->toBase64(format, quality);
    }
    
    return Napi::String::New(env, base64);
}

} // namespace NativeImage
