@echo off
REM 手动执行 ohpm install，避免 DevEco Studio 同步时的批处理递归问题
cd /d "%~dp0"

echo ========================================
echo 手动执行 ohpm install
echo ========================================

REM 清理旧的依赖
if exist "oh_modules" (
    echo 清理 oh_modules...
    rmdir /s /q oh_modules
)

if exist "entry\oh_modules" (
    echo 清理 entry\oh_modules...
    rmdir /s /q entry\oh_modules
)

if exist "oh-package-lock.json5" (
    echo 清理 oh-package-lock.json5...
    del /f /q oh-package-lock.json5
)

if exist "entry\oh-package-lock.json5" (
    echo 清理 entry\oh-package-lock.json5...
    del /f /q entry\oh-package-lock.json5
)

echo.
echo 开始安装依赖...
echo.

REM 使用 DevEco Studio 自带的 ohpm
set "OHPM_PATH=D:\hm\hm\ds\setup\DevEco Studio\tools\ohpm\bin\ohpm.bat"

if exist "%OHPM_PATH%" (
    echo 使用 DevEco Studio 的 ohpm: %OHPM_PATH%
    call "%OHPM_PATH%" install
) else (
    echo 未找到 DevEco Studio 的 ohpm，尝试使用系统 ohpm...
    call ohpm install
)

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo ohpm install 成功！
    echo ========================================
    echo.
    echo 现在可以在 DevEco Studio 中构建项目了
    echo 建议使用以下命令构建（不使用守护进程）：
    echo   hvigorw assembleHap --no-daemon
    echo.
) else (
    echo.
    echo ========================================
    echo ohpm install 失败！
    echo ========================================
    echo.
    echo 请检查：
    echo 1. 网络连接是否正常
    echo 2. ohpm 是否正确安装
    echo 3. 仓库地址是否可访问
    echo.
)

pause
