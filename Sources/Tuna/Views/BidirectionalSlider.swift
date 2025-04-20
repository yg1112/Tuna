import SwiftUI

struct BidirectionalSlider: View {
    @Binding var value: Double

    // 简化常量定义
    private let minValue: Double = -50
    private let maxValue: Double = 50
    private let trackHeight: CGFloat = 4 // 减小高度，更紧凑
    private let thumbSize: CGFloat = 18 // 调整大小

    // 使用更明亮的颜色提高可见性
    private let accentColor = Color.orange

    // 拖动状态
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            // 主布局容器
            ZStack(alignment: .center) {
                // 背景轨道 - 确保可见
                RoundedRectangle(cornerRadius: self.trackHeight / 2)
                    .fill(self.accentColor.opacity(0.3))
                    .frame(height: self.trackHeight)

                // 高亮轨道
                let thumbPosition = ((value - self.minValue) / (self.maxValue - self.minValue)) *
                    geometry.size
                    .width

                // 滑块按钮 - 使用更大、更明显的样式
                Circle()
                    .fill(Color.white)
                    .frame(width: self.thumbSize, height: self.thumbSize)
                    .shadow(color: Color.black.opacity(0.3), radius: 2)
                    .overlay(Circle().stroke(self.accentColor, lineWidth: 1.5))
                    .position(x: thumbPosition, y: geometry.size.height / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                // 直接从拖动位置计算值
                                let newX = min(max(0, gesture.location.x), geometry.size.width)
                                let percentage = newX / geometry.size.width
                                self.value = self
                                    .minValue + (self.maxValue - self.minValue) * percentage
                            }
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 30) // 减小高度从35到30
        .padding(.vertical, 3) // 减小内边距从5到3
    }
}

struct BidirectionalSlider_Previews: PreviewProvider {
    static var previews: some View {
        struct PreviewWrapper: View {
            @State private var value: Double = 0

            var body: some View {
                VStack {
                    Text("Value: \(String(format: "%.1f", self.value))")
                    BidirectionalSlider(value: self.$value)
                        .frame(height: 100)
                        .padding()
                }
                .preferredColorScheme(.dark)
            }
        }

        return PreviewWrapper()
    }
}
