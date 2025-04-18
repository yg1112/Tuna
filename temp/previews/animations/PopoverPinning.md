# 弹出窗口固定功能 (PopoverPinning)

## 功能描述
菜单可固定功能允许用户将Tuna菜单"固定"在屏幕上，防止点击窗口外部时自动关闭。
这对于需要持续使用应用功能时非常有用。

## 技术实现
通过控制NSPopover的behavior属性，在固定状态下使用.applicationDefined行为，
非固定状态下使用.transient行为：

```swift
private func togglePinning() {
    isPinned.toggle()
    if isPinned {
        popover.behavior = .applicationDefined
    } else {
        popover.behavior = .transient
    }
}
```

## 用户体验
- 用户点击固定按钮后，弹出窗口保持打开状态
- 固定按钮图标从"pin"变为"pin.fill"，提供视觉反馈
- 即使用户点击应用外部区域，窗口也不会关闭

## 应用位置
- MenuBarView标题栏右侧的固定按钮
- 与全局事件监控系统协同工作

## 待改进
在应用重启后保持弹出窗口的固定状态（待实现） 