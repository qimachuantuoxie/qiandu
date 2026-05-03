#ifndef NATIVE_PDF_H
#define NATIVE_PDF_H

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <napi/napi.h>

namespace PDF {

struct PdfPage {
    int pageIndex;
    int width;
    int height;
    std::string text;
    std::vector<std::string> images;
};

struct PdfBookmark {
    std::string title;
    int pageIndex;
    int level;
    std::vector<PdfBookmark> children;
};

struct PdfMetadata {
    std::string title;
    std::string author;
    std::string subject;
    std::string keywords;
    std::string creator;
    std::string producer;
    std::string creationDate;
    std::string modDate;
};

struct PdfDocument {
    int pageCount;
    PdfMetadata metadata;
    std::vector<PdfBookmark> bookmarks;
    bool isEncrypted;
    bool isLinearized;
};

class PdfEngine {
public:
    PdfEngine();
    ~PdfEngine();

    bool open(const std::string& pdfPath);
    void close();
    
    PdfDocument getDocument();
    PdfPage getPage(int pageIndex);
    std::string extractText(int pageIndex, bool needLayout = true);
    std::string extractAllText();
    std::vector<uint8_t> renderPage(int pageIndex, int width, int height, int dpi = 150);
    std::vector<uint8_t> renderPageToImage(int pageIndex, const std::string& format, int quality = 90);
    
    bool isOpened() const { return m_opened; }
    int getPageCount() const { return m_pageCount; }

private:
    bool parsePdf();
    bool extractMetadata();
    bool extractBookmarks();

    bool m_opened;
    int m_pageCount;
    std::string m_filePath;
    PdfDocument m_document;
    void* m_pdfHandle;
    std::mutex m_mutex;
};

} // namespace PDF

namespace NativePDF {

Napi::Value OpenPdf(const Napi::CallbackInfo& info);
Napi::Value ClosePdf(const Napi::CallbackInfo& info);
Napi::Value GetPageCount(const Napi::CallbackInfo& info);
Napi::Value GetMetadata(const Napi::CallbackInfo& info);
Napi::Value GetPageText(const Napi::CallbackInfo& info);
Napi::Value GetAllText(const Napi::CallbackInfo& info);
Napi::Value RenderPage(const Napi::CallbackInfo& info);
Napi::Value RenderPageToBase64(const Napi::CallbackInfo& info);
Napi::Value GetBookmarks(const Napi::CallbackInfo& info);
Napi::Value GetPageCountWithDpi(const Napi::CallbackInfo& info);

} // namespace NativePDF

#endif // NATIVE_PDF_H
