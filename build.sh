#!/bin/bash
set -e

# 备份当前应用
if [ -d "Tuna.app" ]; then
    rm -rf "Tuna.app.bak"
    mv "Tuna.app" "Tuna.app.bak"
    echo "已备份旧应用到 Tuna.app.bak"
fi

# 确定Xcode项目路径
PROJECT_PATH="ShortcutCaptureTestApp.xcodeproj"

# 编译应用
xcodebuild -project "$PROJECT_PATH" -scheme "ShortcutCaptureTestApp" -configuration Release clean build

# 从DerivedData复制应用
echo "寻找编译好的应用..."
DERIVED_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "ShortcutCaptureTestApp.app" -type d 2>/dev/null | grep -v "Build/Intermediates" | head -n 1)

if [ -n "$DERIVED_APP" ]; then
    cp -R "$DERIVED_APP" "Tuna.app"
    echo "应用已复制到 Tuna.app"
    # 查看时间戳
    ls -la "Tuna.app"
else
    echo "找不到编译好的应用"
    exit 1
fi

echo "编译完成，您可以通过以下命令启动应用查看日志："
echo "open -n Tuna.app --args -NSApplicationCrashOnExceptions YES" 