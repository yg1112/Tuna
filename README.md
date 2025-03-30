# Tuna

Tuna 是一个简洁的 macOS 菜单栏应用程序，用于快速管理音频输入/输出设备和音量控制。

![Tuna Screenshot](Resources/screenshot.png)

## 功能特点

- 🎧 快速切换音频输入/输出设备
- 🔊 精确的音量控制滑块
- 🖥️ 优雅的菜单栏界面
- ⚡️ 轻量级且高效
- 🎯 专注于核心功能

## 系统要求

- macOS 10.15 (Catalina) 或更高版本
- 约 10MB 可用磁盘空间

## 安装方法

### 方法 1：直接下载

1. 从 [Releases](https://github.com/yourusername/tuna/releases) 页面下载最新版本的 `Tuna.app`
2. 将应用拖入 Applications 文件夹
3. 双击运行 Tuna

### 方法 2：从源码编译

1. 确保已安装 Xcode 14.0 或更高版本
2. 克隆仓库：
   ```bash
   git clone https://github.com/yourusername/tuna.git
   cd tuna
   ```
3. 使用 Swift Package Manager 编译：
   ```bash
   swift build -c release
   ```
4. 运行应用：
   ```bash
   swift run
   ```

## 使用说明

1. 启动应用后，在菜单栏中寻找金枪鱼图标
2. 点击图标显示下拉菜单
3. 在菜单中可以：
   - 选择音频输入/输出设备
   - 调节各设备音量
   - 查看当前活动设备

## 权限说明

首次运行时，应用会请求以下权限：
- 麦克风访问权限（用于音频输入设备管理）
- 辅助功能权限（用于系统音量控制）

## 问题反馈

如果您遇到任何问题或有功能建议，请：
1. 检查 [Issues](https://github.com/yourusername/tuna/issues) 页面是否已有相关讨论
2. 如果没有，请创建新的 Issue
3. 在反馈中请详细描述：
   - 系统版本
   - 问题复现步骤
   - 期望的行为
   - 实际的行为

## 开发计划

- [ ] 添加快捷键支持
- [ ] 实现音量电平显示
- [ ] 添加设备自动切换规则
- [ ] 支持设备组管理

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。 