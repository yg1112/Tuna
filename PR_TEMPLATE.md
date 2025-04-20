## 标题
ci(make): add clean target and solidify make workflow

## 描述
此PR增加了缺失的`clean`目标并验证了完整的Makefile工作流。

## 主要修改
- 添加了`.PHONY: bootstrap lint snapshot test clean all`
- 简化了Makefile，移除了依赖xcodebuild的操作
- 优化了clean目标：`rm -rf .build`
- 更新了文档，推荐使用`make bootstrap && make test`

## 本地验证
- [x] `make clean`成功执行
- [x] `make bootstrap && make test`无需手动干预完成

## 检查列表
- [x] 代码遵循项目编码规范
- [x] 所有测试通过
- [x] 文档已更新

## CI状态
等待CI完成验证。

## 注意事项
CI作业"Tuna CI / test"需要通过，以确认修复有效。 