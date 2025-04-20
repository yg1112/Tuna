// @module: TunaBanner
// @created_by_cursor: yes
// @summary: 定义通知横幅组件，用于显示错误信息等
// @depends_on: TunaTheme

import SwiftUI

/// 横幅类型
enum BannerType {
    case error
    case warning
    case success
    case info

    var iconName: String {
        switch self {
            case .error: "exclamationmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .success: "checkmark.circle.fill"
            case .info: "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
            case .error: .red
            case .warning: .orange
            case .success: .green
            case .info: Color.blue
        }
    }
}

/// 通知横幅组件
struct TunaBanner: View {
    let message: String
    let type: BannerType
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    @Binding var isPresented: Bool

    @State private var offset: CGFloat = -100

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: self.type.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(self.type.color)

                // 消息文本
                Text(self.message)
                    .font(.system(size: 14))
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.leading)

                Spacer()

                // 操作按钮（如果有）
                if let actionLabel, let action {
                    Button(action: {
                        action()
                    }) {
                        Text(actionLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(self.type.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(self.type.color.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 关闭按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 0.18, green: 0.18, blue: 0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(self.type.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .offset(y: self.offset)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.offset = 0
                }

                // 设置自动关闭计时器（5秒）
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if self.isPresented {
                        withAnimation {
                            self.isPresented = false
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
    }
}

// 用于预览的示例
struct TunaBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TunaBanner(
                message: "No API key provided. Please add your OpenAI API key in Settings.",
                type: .error,
                action: { print("Settings tapped") },
                actionLabel: "Settings",
                isPresented: .constant(true)
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }
}
