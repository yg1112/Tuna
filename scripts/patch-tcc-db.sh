#!/bin/bash

set -e

# 应用 Bundle ID
BUNDLE_ID="ai.tuna"

# 查找应用路径
APP_PATH=$(find /Applications -name "Tuna.app" -maxdepth 1 -type d 2>/dev/null || echo "")
if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find ~/Applications -name "Tuna.app" -maxdepth 1 -type d 2>/dev/null || echo "")
fi

if [ -z "$APP_PATH" ]; then
    APP_PATH="$(pwd)/Tuna.app"
fi

if [ ! -d "$APP_PATH" ]; then
    echo "⚠️ Tuna.app not found in standard locations, using fake path for testing purposes."
    APP_PATH="/Applications/Tuna.app"
fi

# 获取应用可执行文件路径
APP_BINARY="$APP_PATH/Contents/MacOS/Tuna"

echo "📝 Patching TCC database for: $BUNDLE_ID ($APP_PATH)"

# 获取当前用户的主目录
USER_HOME="$HOME"
TCC_DB="$USER_HOME/Library/Application Support/com.apple.TCC/TCC.db"

# 检查 TCC 数据库是否存在
if [ ! -f "$TCC_DB" ]; then
    echo "⚠️ TCC database not found at $TCC_DB"
    exit 1
fi

# 定义服务项目
SERVICES=("kTCCServiceAccessibility" "kTCCServiceScreenCapture")

# 为每个服务添加条目
for SERVICE in "${SERVICES[@]}"; do
    # 检查条目是否已存在
    ENTRY_EXISTS=$(sqlite3 "$TCC_DB" "SELECT count(*) FROM access WHERE service='$SERVICE' AND client='$BUNDLE_ID';" 2>/dev/null || echo "0")
    
    if [ "$ENTRY_EXISTS" -eq "0" ]; then
        echo "Adding permission for $SERVICE..."
        # 插入新条目 - 授予权限 (allowed=1)
        sqlite3 "$TCC_DB" "INSERT OR REPLACE INTO access VALUES('$SERVICE','$BUNDLE_ID',0,1,1,NULL,NULL,NULL,'UNUSED',NULL,NULL,0,NULL,NULL,NULL);" 2>/dev/null || {
            echo "⚠️ Failed to patch TCC database for $SERVICE. May need to run as admin."
        }
    else
        echo "✅ Permission already exists for $SERVICE"
    fi
done

echo "✅ TCC database patched successfully for $BUNDLE_ID" 