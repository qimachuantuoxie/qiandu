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
# DJVU 解析器（需要 djvulibre 库）
# ============================================
# 注意：需要先编译并集成 djvulibre 库
# 取消注释并配置路径后启用
# add_library(djvulibre STATIC IMPORTED)
# set_target_properties(djvulibre PROPERTIES IMPORTED_LOCATION
#     ${CMAKE_CURRENT_SOURCE_DIR}/libs/${CMAKE_ANDROID_ARCH_ABI}/libdjvulibre.a)

add_library(djvuparser SHARED
    native_djvu.cpp
)

target_include_directories(djvuparser PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# 如果启用了 djvulibre，取消下面的注释
# target_link_libraries(djvuparser PUBLIC libace_napi.z libhilog_ndk.z djvulibre)
target_link_libraries(djvuparser PUBLIC libace_napi.z libhilog_ndk.z)

# ============================================
# CHM 解析器（需要 chmlib 库）
# ============================================
# 注意：需要先编译并集成 chmlib 库
# 取消注释并配置路径后启用
# add_library(chmlib STATIC IMPORTED)
# set_target_properties(chmlib PROPERTIES IMPORTED_LOCATION
#     ${CMAKE_CURRENT_SOURCE_DIR}/libs/${CMAKE_ANDROID_ARCH_ABI}/libchm.a)

add_library(chmparser SHARED
    native_chm.cpp
)

target_include_directories(chmparser PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# 如果启用了 chmlib，取消下面的注释
# target_link_libraries(chmparser PUBLIC libace_napi.z libhilog_ndk.z chmlib)
target_link_libraries(chmparser PUBLIC libace_napi.z libhilog_ndk.z)
