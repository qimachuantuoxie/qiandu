/**
 * CHM 解析器头文件
 */

#ifndef CHM_PARSER_H
#define CHM_PARSER_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * CHM 文档信息结构
 */
typedef struct {
    char title[256];
    char author[256];
    int pageCount;
    int fileCount;
    int fileSize;
    char encoding[64];
} ChmInfo;

/**
 * CHM 章节信息结构
 */
typedef struct {
    char title[512];
    char path[1024];
    int offset;
    int length;
} ChmChapter;

/**
 * 解析 CHM 文件基本信息
 * 
 * @param filePath 文件路径
 * @param info 输出参数，文档信息
 * @return 0 成功，-1 失败
 */
int ParseChmInfo(const char* filePath, ChmInfo* info);

/**
 * 提取 CHM 中的所有 HTML 内容
 * 
 * @param filePath 文件路径
 * @return HTML 内容字符串（调用者负责释放）
 */
char* ExtractChmHtml(const char* filePath);

/**
 * 获取 CHM 章节列表
 * 
 * @param filePath 文件路径
 * @param chapters 输出参数，章节数组
 * @param maxChapters 最大章节数
 * @return 实际章节数，-1 表示失败
 */
int GetChmChapters(const char* filePath, ChmChapter* chapters, int maxChapters);

#ifdef __cplusplus
}
#endif

#endif // CHM_PARSER_H
