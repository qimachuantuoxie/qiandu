/**
 * CBZ 解析器头文件
 */

#ifndef CBZ_PARSER_H
#define CBZ_PARSER_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * CBZ 文档信息结构
 */
typedef struct {
    char title[256];
    char author[256];
    int pageCount;
} CbzInfo;

/**
 * 解析 CBZ 文件基本信息
 * 
 * @param filePath 文件路径
 * @param info 输出参数，文档信息
 * @return 0 成功，-1 失败
 */
int ParseCbzInfo(const char* filePath, CbzInfo* info);

/**
 * 获取 CBZ 页面数量
 * 
 * @param filePath 文件路径
 * @return 页面数量，-1 表示失败
 */
int GetCbzPageCount(const char* filePath);

/**
 * 获取 CBZ 页面图片数据
 * 
 * @param filePath 文件路径
 * @param pageIndex 页码（从0开始）
 * @param outSize 输出参数，图片数据大小
 * @return 图片数据指针（调用者负责释放），失败返回 nullptr
 */
unsigned char* GetCbzPageImage(
    const char* filePath,
    int pageIndex,
    int* outSize
);

/**
 * 获取 CBZ 页面文件名列表
 * 
 * @param filePath 文件路径
 * @param fileNames 输出参数，文件名数组（调用者负责释放每个字符串）
 * @param maxCount 最大数量
 * @return 实际返回的文件名数量，-1 表示失败
 */
int GetCbzPageFileNames(
    const char* filePath,
    char** fileNames,
    int maxCount
);

#ifdef __cplusplus
}
#endif

#endif // CBZ_PARSER_H
