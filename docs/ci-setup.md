# CI/CD 设置指南

本文档描述了 Tuna 项目的 CI/CD 设置和自动化测试流程。

## 前提条件

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.7 或更高版本

## 自动化工具

项目使用以下工具进行 CI/CD 自动化：

- **GitHub Actions**：用于运行自动化测试和部署
- **SwiftFormat**：代码格式化工具
- **XCBeautify**：改进 Xcode 构建输出格式
- **SnapshotTesting**：通过 SwiftPM 自动获取，用于 UI 快照测试

## 本地开发设置

要在本地设置开发环境并运行测试，请执行以下命令：

```bash
make bootstrap && make test
```

这将安装所有必要的工具并运行测试套件。

## Makefile 命令

项目中包含以下 Makefile 目标：

- `make bootstrap`：设置开发环境，安装所需的工具
- `make lint`：运行代码格式化检查
- `make snapshot`：仅运行快照测试
- `make test`：运行所有测试
- `make clean`：清理构建产物

## CI 流程

当推送到 `main` 分支或创建 PR 时，GitHub Actions 会自动运行以下步骤：

1. 检出代码
2. 设置 Swift 环境
3. 安装依赖项
4. 引导环境
5. 运行代码格式检查
6. 运行快照测试
7. 运行单元测试
8. 上传测试结果

## 自定义 CI 设置

要自定义 CI 设置，可以编辑以下文件：

- `.github/workflows/ci.yml`：GitHub Actions 工作流配置
- `Scripts/ci-setup.sh`：CI 环境设置脚本
- `Scripts/patch-tcc-db.sh`：TCC 数据库补丁脚本（用于权限管理）

## 注意事项

- SnapshotTesting 库通过 SwiftPM 自动获取，无需额外安装步骤
- 快照测试可能在不同环境下产生差异，允许在 CI 中失败但会上传差异结果
- TCC 数据库补丁脚本可能需要管理员权限才能运行 