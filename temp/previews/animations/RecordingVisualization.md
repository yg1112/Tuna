# 录音可视化效果 (RecordingVisualization)

## 视觉效果描述
录音状态可视化效果使用动态的音频条形图，根据录音输入电平实时变化高度。
现在使用DesignTokens.Colors.critical颜色（红色），以提供更加一致和醒目的视觉反馈。

## 技术实现
动画效果通过AudioVisualizerBar组件实现，每个条形的高度随机变化，
模拟音频输入的变化，同时颜色从硬编码RGB值更改为使用设计令牌的critical颜色。

## 用户体验
- 当用户开始录音时，条形图随机高度变化，提供实时反馈
- 录音按钮背景色变为红色，使用DesignTokens.Colors.critical
- 状态提示文本更新为"Listening..."

## 实现代码
```swift
struct AudioVisualizerBar: View {
    let isRecording: Bool
    @State private var height: CGFloat = 5
    
    // 定时器状态
    @State private var timer: Timer?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(DesignTokens.Colors.accent) // 使用设计令牌颜色
            .frame(width: 2, height: height)
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
    }
    
    private func startAnimation() {
        // 启动动画逻辑
        // ...
    }
    
    private func stopAnimation() {
        // 停止动画逻辑
        // ...
    }
}
```

## 应用位置
- QuickDictationView组件中使用此动画
- TunaDictationView组件中使用此动画
- 与录音状态指示器配合使用 