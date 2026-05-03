// Native PDF 解析头文件
#pragma once

struct NativePdfInfo {
    char title[256];
    char author[256];
    int pageCount;
    int errorCode;
};

NativePdfInfo ParsePdfInfo(const char* filePath);
