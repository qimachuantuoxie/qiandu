#ifndef NATIVE_OCR_H
#define NATIVE_OCR_H

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <napi/napi.h>

namespace OCR {

struct TextBlock {
    std::string text;
    float confidence;
    int x;
    int y;
    int width;
    int height;
    std::vector<TextBlock> lines;
};

struct OCRResult {
    std::string fullText;
    float averageConfidence;
    int imageWidth;
    int imageHeight;
    std::vector<TextBlock> blocks;
    bool success;
    std::string errorMessage;
};

class OCREngine {
public:
    OCREngine();
    ~OCREngine();

    bool initialize(const std::string& tessdataPath, const std::string& language);
    OCRResult recognize(const std::string& imagePath, bool needPosition = true);
    std::vector<OCRResult> recognizeBatch(const std::vector<std::string>& imagePaths);
    void setLanguage(const std::string& language);
    void setPageSegMode(int mode);
    void setOCREngineMode(int mode);
    void destroy();

    bool isInitialized() const { return m_initialized; }

private:
    bool preprocessImage(const std::string& imagePath, std::vector<uint8_t>& outputBuffer);
    bool loadImage(const std::string& imagePath, int& width, int& height, int& channels);

    bool m_initialized;
    std::string m_tessdataPath;
    std::string m_language;
    int m_pageSegMode;
    int m_oemMode;
    void* m_tessHandle;
    std::mutex m_mutex;
};

} // namespace OCR

namespace NativeOCR {

Napi::Value InitOCREngine(const Napi::CallbackInfo& info);
Napi::Value RecognizeText(const Napi::CallbackInfo& info);
Napi::Value RecognizeTextBatch(const Napi::CallbackInfo& info);
Napi::Value SetLanguage(const Napi::CallbackInfo& info);
Napi::Value DestroyOCREngine(const Napi::CallbackInfo& info);
Napi::Value GetEngineStatus(const Napi::CallbackInfo& info);

} // namespace NativeOCR

#endif // NATIVE_OCR_H
