// Native Zip 解析头文件
#pragma once

// 解析 ZIP 文件中的文件数量
int ParseZipFileCount(const char* filePath);

// 提取文件内容到缓冲区
int ExtractZipFileToBuffer(const char* filePath, const char* entryName, char* buffer, int bufferSize);
