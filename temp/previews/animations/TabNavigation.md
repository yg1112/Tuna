# 标签导航动画 (TabNavigation)

## 视觉效果描述
标签切换使用平滑的过渡动画，带有0.2秒的动画时长。当用户点击不同标签时，
内容区域会平滑过渡到新选中的标签内容，增强用户体验。

## 技术实现
动画效果通过SwiftUI的withAnimation函数实现，使用ease-in-out动画曲线：

```swift
withAnimation(.easeInOut(duration: 0.2)) {
    selectedTab = newTab
}
```

## 用户体验
- 点击标签后，内容区域平滑切换
- 标签文本颜色变化，选中标签使用accent颜色
- 底部指示条滑动到当前选中标签下方

## 应用位置
- MenuBarView中的标签导航组件
- 用于设备、语音转写和统计标签之间的切换 