#include "native_pdf.h"
#include <hilog/log.h>
#include <cstring>
#include <fstream>

#undef LOG_TAG
#define LOG_TAG "NativePDF"

#define PDF_LOGI(...) OH_LOG_INFO(LOG::ALOG_APP, __VA_ARGS__)
#define PDF_LOGE(...) OH_LOG_ERROR(LOG::ALOG_APP, __VA_ARGS__)

namespace PDF {

PdfEngine::PdfEngine() 
    : m_opened(false)
    , m_pageCount(0)
    , m_pdfHandle(nullptr) {
    PDF_LOGI("PDF Engine created");
}

PdfEngine::~PdfEngine() {
    close();
}

bool PdfEngine::open(const std::string& pdfPath) {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    if (m_opened) {
        close();
    }
    
    m_filePath = pdfPath;
    PDF_LOGI("Opening PDF: %{public}s", pdfPath.c_str());
    
    // In production, load PDF using MuPDF or Poppler:
    // m_pdfHandle = fz_open_document(context, pdfPath.c_str());
    // m_pageCount = fz_count_pages(context, doc);
    
    // Simulate PDF opening
    m_pageCount = 100; // Simulated
    m_opened = true;
    
    parsePdf();
    extractMetadata();
    extractBookmarks();
    
    PDF_LOGI("PDF opened successfully, pages: %{public}d", m_pageCount);
    return true;
}

void PdfEngine::close() {
    std::lock_guard<std::mutex> lock(m_mutex);
    
    if (m_pdfHandle != nullptr) {
        // fz_close_document(context, doc);
        m_pdfHandle = nullptr;
    }
    
    m_opened = false;
    m_pageCount = 0;
    PDF_LOGI("PDF closed");
}

PdfDocument PdfEngine::getDocument() {
    return m_document;
}

PdfPage PdfEngine::getPage(int pageIndex) {
    PdfPage page;
    page.pageIndex = pageIndex;
    page.width = 595;  // A4 width in points
    page.height = 842; // A4 height in points
    
    // In production: fz_page *page = fz_load_page(context, doc, pageIndex);
    // Then render or extract text
    
    page.text = "[Page " + std::to_string(pageIndex + 1) + " content]";
    
    return page;
}

std::string PdfEngine::extractText(int pageIndex, bool needLayout) {
    if (!m_opened || pageIndex < 0 || pageIndex >= m_pageCount) {
        return "";
    }
    
    PDF_LOGI("Extracting text from page %{public}d", pageIndex);
    
    // In production, use MuPDF:
    // fz_page *page = fz_load_page(context, doc, pageIndex);
    // fz_stext_page *text = fz_new_stext_page_from_page(context, page, ...);
    // Extract text using text analyzer
    
    std::string text = "第 " + std::to_string(pageIndex + 1) + " 页内容\n\n";
    text += "这是从PDF提取的文本内容。\n";
    text += "支持多段落、多页面提取。\n";
    text += "保留基本排版格式。\n";
    
    return text;
}

std::string PdfEngine::extractAllText() {
    if (!m_opened) {
        return "";
    }
    
    std::string allText;
    for (int i = 0; i < m_pageCount; i++) {
        allText += extractText(i);
        allText += "\n\n--- 第 " + std::to_string(i + 1) + " 页结束 ---\n\n";
    }
    
    return allText;
}

std::vector<uint8_t> PdfEngine::renderPage(int pageIndex, int width, int height, int dpi) {
    std::vector<uint8_t> pixels;
    
    if (!m_opened || pageIndex < 0 || pageIndex >= m_pageCount) {
        return pixels;
    }
    
    // In production, use MuPDF to render:
    // fz_page *page = fz_load_page(context, doc, pageIndex);
    // fz_matrix ctm = fz_scale(dpi/72.0f, dpi/72.0f);
    // fz_pixmap *pix = fz_render_pixmap_from_page(context, page, ctm, ...);
    // Copy pixels to output buffer
    
    // Calculate pixel buffer size (RGBA)
    size_t bufferSize = width * height * 4;
    pixels.resize(bufferSize, 255); // White background
    
    PDF_LOGI("Rendering page %{public}d to %{public}x%{public}d @ %{public}d DPI", 
              pageIndex, width, height, dpi);
    
    return pixels;
}

std::vector<uint8_t> PdfEngine::renderPageToImage(int pageIndex, const std::string& format, int quality) {
    // Default render at reasonable resolution
    return renderPage(pageIndex, 1200, 1600, 150);
}

bool PdfEngine::parsePdf() {
    // Parse PDF structure
    return true;
}

bool PdfEngine::extractMetadata() {
    m_document.pageCount = m_pageCount;
    m_document.metadata.title = "PDF Document";
    m_document.metadata.author = "Unknown";
    m_document.metadata.subject = "";
    m_document.metadata.keywords = "";
    m_document.metadata.creator = "千读阅界";
    m_document.metadata.producer = "PDF Engine";
    m_document.metadata.creationDate = "";
    m_document.metadata.modDate = "";
    m_document.isEncrypted = false;
    m_document.isLinearized = false;
    
    return true;
}

bool PdfEngine::extractBookmarks() {
    // Extract PDF bookmarks/outline
    // In production: fz_outline *outline = fz_load_outline(context, doc);
    
    m_document.bookmarks.clear();
    
    // Sample bookmark
    PdfBookmark bookmark;
    bookmark.title = "第一章";
    bookmark.pageIndex = 0;
    bookmark.level = 1;
    m_document.bookmarks.push_back(bookmark);
    
    return true;
}

} // namespace PDF

// NAPI bindings
namespace NativePDF {

static std::shared_ptr<PDF::PdfEngine> g_pdfEngine = nullptr;

Napi::Value OpenPdf(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsString()) {
        Napi::TypeError::New(env, "Invalid arguments: pdfPath required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    std::string pdfPath = info[0].As<Napi::String>().Utf8Value();
    
    PDF_LOGI("Opening PDF via NAPI: %{public}s", pdfPath.c_str());
    
    if (g_pdfEngine == nullptr) {
        g_pdfEngine = std::make_shared<PDF::PdfEngine>();
    }
    
    bool success = g_pdfEngine->open(pdfPath);
    
    Napi::Object result = Napi::Object::New(env);
    result.Set("success", Napi::Boolean::New(env, success));
    result.Set("pageCount", Napi::Number::New(env, g_pdfEngine->getPageCount()));
    result.Set("filePath", Napi::String::New(env, pdfPath));
    
    return result;
}

Napi::Value ClosePdf(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (g_pdfEngine != nullptr) {
        g_pdfEngine->close();
    }
    
    return Napi::Boolean::New(env, true);
}

Napi::Value GetPageCount(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    int pageCount = 0;
    if (g_pdfEngine != nullptr) {
        pageCount = g_pdfEngine->getPageCount();
    }
    
    return Napi::Number::New(env, pageCount);
}

Napi::Value GetMetadata(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    Napi::Object metadata = Napi::Object::New(env);
    
    if (g_pdfEngine != nullptr && g_pdfEngine->isOpened()) {
        PDF::PdfDocument doc = g_pdfEngine->getDocument();
        metadata.Set("title", Napi::String::New(env, doc.metadata.title));
        metadata.Set("author", Napi::String::New(env, doc.metadata.author));
        metadata.Set("subject", Napi::String::New(env, doc.metadata.subject));
        metadata.Set("keywords", Napi::String::New(env, doc.metadata.keywords));
        metadata.Set("creator", Napi::String::New(env, doc.metadata.creator));
        metadata.Set("producer", Napi::String::New(env, doc.metadata.producer));
        metadata.Set("pageCount", Napi::Number::New(env, doc.pageCount));
        metadata.Set("isEncrypted", Napi::Boolean::New(env, doc.isEncrypted));
    }
    
    return metadata;
}

Napi::Value GetPageText(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments: pageIndex required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    int pageIndex = info[0].As<Napi::Number>().Int32Value();
    bool needLayout = info.Length() > 1 && info[1].IsBoolean() ? info[1].As<Napi::Boolean>().Value() : true;
    
    std::string text = "";
    if (g_pdfEngine != nullptr && g_pdfEngine->isOpened()) {
        text = g_pdfEngine->extractText(pageIndex, needLayout);
    }
    
    return Napi::String::New(env, text);
}

Napi::Value GetAllText(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    std::string text = "";
    if (g_pdfEngine != nullptr && g_pdfEngine->isOpened()) {
        text = g_pdfEngine->extractAllText();
    }
    
    return Napi::String::New(env, text);
}

Napi::Value RenderPage(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 3 || !info[0].IsNumber() || !info[1].IsNumber() || !info[2].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments: pageIndex, width, height required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    int pageIndex = info[0].As<Napi::Number>().Int32Value();
    int width = info[1].As<Napi::Number>().Int32Value();
    int height = info[2].As<Napi::Number>().Int32Value();
    int dpi = info.Length() > 3 && info[3].IsNumber() ? info[3].As<Napi::Number>().Int32Value() : 150;
    
    std::vector<uint8_t> pixels;
    if (g_pdfEngine != nullptr && g_pdfEngine->isOpened()) {
        pixels = g_pdfEngine->renderPage(pageIndex, width, height, dpi);
    }
    
    Napi::Object result = Napi::Object::New(env);
    result.Set("width", Napi::Number::New(env, width));
    result.Set("height", Napi::Number::New(env, height));
    result.Set("data", Napi::Buffer<uint8_t>::New(env, pixels.size()));
    
    return result;
}

Napi::Value RenderPageToBase64(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 1 || !info[0].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments: pageIndex required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    int pageIndex = info[0].As<Napi::Number>().Int32Value();
    
    std::string base64 = "";
    if (g_pdfEngine != nullptr && g_pdfEngine->isOpened()) {
        auto pixels = g_pdfEngine->renderPageToImage(pageIndex, "png", 90);
        // Convert to base64 (simplified)
        base64 = "[BASE64_IMAGE_DATA]";
    }
    
    return Napi::String::New(env, base64);
}

Napi::Value GetBookmarks(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    Napi::Array bookmarks = Napi::Array::New(env, 0);
    
    if (g_pdfEngine != nullptr && g_pdfEngine->isOpened()) {
        PDF::PdfDocument doc = g_pdfEngine->getDocument();
        
        for (size_t i = 0; i < doc.bookmarks.size(); i++) {
            Napi::Object bookmark = Napi::Object::New(env);
            bookmark.Set("title", Napi::String::New(env, doc.bookmarks[i].title));
            bookmark.Set("pageIndex", Napi::Number::New(env, doc.bookmarks[i].pageIndex));
            bookmark.Set("level", Napi::Number::New(env, doc.bookmarks[i].level));
            bookmarks.Set(i, bookmark);
        }
    }
    
    return bookmarks;
}

Napi::Value GetPageCountWithDpi(const Napi::CallbackInfo& info) {
    Napi::Env env = info.Env();
    
    if (info.Length() < 2 || !info[0].IsNumber() || !info[1].IsNumber()) {
        Napi::TypeError::New(env, "Invalid arguments: pageIndex and dpi required")
            .ThrowAsJavaScriptException();
        return env.Null();
    }
    
    int pageIndex = info[0].As<Napi::Number>().Int32Value();
    int dpi = info[1].As<Napi::Number>().Int32Value();
    
    PDF::PdfPage page;
    if (g_pdfEngine != nullptr && g_pdfEngine->isOpened()) {
        page = g_pdfEngine->getPage(pageIndex);
    }
    
    double scale = dpi / 72.0;
    int width = static_cast<int>(page.width * scale);
    int height = static_cast<int>(page.height * scale);
    
    Napi::Object result = Napi::Object::New(env);
    result.Set("width", Napi::Number::New(env, width));
    result.Set("height", Napi::Number::New(env, height));
    result.Set("dpi", Napi::Number::New(env, dpi));
    
    return result;
}

} // namespace NativePDF
