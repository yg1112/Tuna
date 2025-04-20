#!/bin/bash

set -e

# 安装必要的开发工具

# 安装 Homebrew（如果需要）
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 安装 xcbeautify
if ! command -v xcbeautify &> /dev/null; then
    echo "Installing xcbeautify..."
    brew install xcbeautify
fi

# 安装 swiftformat
if ! command -v swiftformat &> /dev/null; then
    echo "Installing swiftformat..."
    brew install swiftformat
fi

# 安装 jq (用于JSON处理)
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    brew install jq
fi

# 安装 mint (用于管理Swift命令行工具)
if ! command -v mint &> /dev/null; then
    echo "Installing mint..."
    brew install mint
fi

# 安装 xcodes (用于管理Xcode版本)
if ! command -v xcodes &> /dev/null; then
    echo "Installing xcodes..."
    brew install robotsandpencils/made/xcodes
fi

echo "✅ CI Setup completed successfully" 