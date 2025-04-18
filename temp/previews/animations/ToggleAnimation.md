# 开关切换动画 (ToggleAnimation)

## 视觉效果描述
开关切换使用0.2秒弹簧动画效果，提供流畅且有弹性的交互体验。
当用户点击开关时，滑块平滑移动到另一端，并伴随背景颜色的变化。

## 技术实现
动画效果通过自定义的ModernToggleStyle实现，使用弹簧动画：

```swift
.animation(.spring(response: 0.2, dampingFraction: 0.8), value: isOn)
```

## 用户体验
- 开关状态变化时，滑块平滑移动
- 背景颜色从灰色渐变到accent颜色（薄荷绿）
- 弹簧动画添加轻微的过冲效果，增强交互的物理感

## 应用位置
- 设置界面中的所有开关控件
- DictationView中的功能开关
- 快捷键设置部分

## 实现代码
```swift
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            // 开关内容
            HStack {
                configuration.label
                Spacer()
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? DesignTokens.Colors.accent : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 29)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .shadow(radius: 1)
                            .padding(2)
                            .offset(x: configuration.isOn ? 10 : -10)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
``` 