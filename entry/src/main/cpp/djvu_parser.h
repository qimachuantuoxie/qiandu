/**
 * DJVU 解析器头文件
 */

#ifndef DJVU_PARSER_H
#define DJVU_PARSER_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * DJVU 文档信息结构
 */
typedef struct {
    char title[256];
    char author[256];
    int pageCount;
    int width;
    int height;
} DjvuInfo;

/**
 * 解析 DJVU 文件基本信息
 * 
 * @param filePath 文件路径
 * @param info 输出参数，文档信息
 * @return 0 成功，-1 失败
 */
int ParseDjvuInfo(const char* filePath, DjvuInfo* info);

/**
 * 渲染 DJVU 页面为 RGBA 位图
 * 
 * @param filePath 文件路径
 * @param pageIndex 页码（从0开始）
 * @param width 输出宽度
 * @param height 输出高度
 * @param outWidth 实际输出宽度
 * @param outHeight 实际输出高度
 * @return RGBA 数据指针（调用者负责释放），失败返回 nullptr
 */
unsigned char* RenderDjvuPage(
    const char* filePath,
    int pageIndex,
    int width,
    int height,
    int* outWidth,
    int* outHeight
);

/**
 * 获取 DJVU 页面数量
 * 
 * @param filePath 文件路径
 * @return 页面数量，-1 表示失败
 */
int GetDjvuPageCount(const char* filePath);

#ifdef __cplusplus
}
#endif

#endif // DJVU_PARSER_H
