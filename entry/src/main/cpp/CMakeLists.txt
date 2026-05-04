# CMake 配置文件
# 定义如何编译 C++ 源码

cmake_minimum_required(VERSION 3.4.1)
project("qianduyuejie_native")

# 指定 C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

# 收集源文件
file(GLOB CPP_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
)

# 构建共享库 libentry.so
add_library(entry SHARED ${CPP_SOURCES})

# 链接必要的系统库
target_link_libraries(entry PUBLIC
    libace_napi.z       # NAPI 核心
    libhilog_ndk.z      # 日志 (如果在 cpp 中使用了)
)

# ============================================
# ImageKit 图像处理库
# ============================================
add_library(imagekit SHARED
    imagekit/imagekit_napi.cpp
    imagekit/image_decode.cpp
    imagekit/image_encode.cpp
    imagekit/image_resize.cpp
    imagekit/image_rotate.cpp
    imagekit/image_crop.cpp
    imagekit/image_metadata.cpp
)

# 包含头文件目录
target_include_directories(imagekit PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# 链接 NAPI 和日志库
target_link_libraries(imagekit PUBLIC libace_napi.z libhilog_ndk.z)

# ============================================
# CHM 解析器库
# ============================================
add_library(chm_parser SHARED
    chm_parser.cpp
)

# 链接必要的库
target_link_libraries(chm_parser PUBLIC
    libace_napi.z       # NAPI 核心
    libhilog_ndk.z      # 日志
    libz.a             # zlib 压缩库
)

# ============================================
# DjVu 解析器库
# ============================================
add_library(djvu_parser SHARED
    djvu_parser.cpp
)

# 链接必要的库
target_link_libraries(djvu_parser PUBLIC
    libace_napi.z       # NAPI 核心
    libhilog_ndk.z      # 日志
    libjpeg.a           # JPEG 库（DjVu 依赖）
    libtiff.a           # TIFF 库（DjVu 依赖）
)
