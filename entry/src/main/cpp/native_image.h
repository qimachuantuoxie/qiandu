#ifndef NATIVE_IMAGE_H
#define NATIVE_IMAGE_H

#include <string>
#include <vector>
#include <memory>
#include <napi/napi.h>

namespace ImageProcessing {

struct ImageInfo {
    int width;
    int height;
    int channels;
    int format;
    size_t dataSize;
};

struct ImageRegion {
    int x;
    int y;
    int width;
    int height;
};

class ImageEngine {
public:
    ImageEngine();
    ~ImageEngine();

    bool loadImage(const std::string& imagePath);
    bool loadFromBuffer(const std::vector<uint8_t>& buffer);
    void release();
    
    ImageInfo getInfo();
    std::vector<uint8_t> resize(int width, int height, const std::string& filter = "bilinear");
    std::vector<uint8_t> crop(const ImageRegion& region);
    std::vector<uint8_t> rotate(int angle);
    std::vector<uint8_t> grayscale();
    std::vector<uint8_t> threshold(int threshold = 128);
    std::vector<uint8_t> adjustBrightness(float factor);
    std::vector<uint8_t> adjustContrast(float factor);
    std::vector<uint8_t> denoise(int strength = 3);
    std::vector<uint8_t> sharpen(float amount = 1.0f);
    
    bool saveToFile(const std::string& path, const std::string& format = "png", int quality = 90);
    std::string toBase64(const std::string& format = "png", int quality = 90);
    
    bool isLoaded() const { return m_loaded; }

private:
    bool m_loaded;
    int m_width;
    int m_height;
    int m_channels;
    std::vector<uint8_t> m_data;
    std::string m_format;
};

} // namespace ImageProcessing

namespace NativeImage {

Napi::Value LoadImage(const Napi::CallbackInfo& info);
Napi::Value ReleaseImage(const Napi::CallbackInfo& info);
Napi::Value GetImageInfo(const Napi::CallbackInfo& info);
Napi::Value ResizeImage(const Napi::CallbackInfo& info);
Napi::Value CropImage(const Napi::CallbackInfo& info);
Napi::Value RotateImage(const Napi::CallbackInfo& info);
Napi::Value GrayscaleImage(const Napi::CallbackInfo& info);
Napi::Value ThresholdImage(const Napi::CallbackInfo& info);
Napi::Value AdjustBrightness(const Napi::CallbackInfo& info);
Napi::Value AdjustContrast(const Napi::CallbackInfo& info);
Napi::Value DenoiseImage(const Napi::CallbackInfo& info);
Napi::Value SharpenImage(const Napi::CallbackInfo& info);
Napi::Value SaveImage(const Napi::CallbackInfo& info);
Napi::Value ImageToBase64(const Napi::CallbackInfo& info);

} // namespace NativeImage

#endif // NATIVE_IMAGE_H
