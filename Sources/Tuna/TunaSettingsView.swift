import SwiftUI
import AppKit
import os.log

struct SystemToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.green : Color(NSColor.darkGray))
                .frame(width: 50, height: 28)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 1)
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 12 : -12)
                        .animation(.spring(response: 0.2), value: configuration.isOn)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TunaSettingsView: View {
    @StateObject private var settings = TunaSettings.shared
    @State private var isProcessingLoginSetting = false
    @State private var actionFeedback = ""
    private let logger = Logger(subsystem: "com.tuna.app", category: "SettingsView")
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Debug Settings")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Launch at Login - 最简化版本
            HStack {
                Text("Launch at Login")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                
                Button(action: {
                    toggleLoginItem()
                }) {
                    Text(settings.launchAtLogin ? "Disable" : "Enable")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(isProcessingLoginSetting)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            
            if !actionFeedback.isEmpty {
                Text(actionFeedback)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
            }
            
            // 添加一个日志按钮，用于验证日志刷新是否正常工作
            Button(action: {
                print("[测试] 这是一个测试日志消息")
                fflush(stdout)
            }) {
                Text("生成测试日志")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(width: 400, height: 300)
        .padding(20)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .onAppear {
            print("[视图] 设置视图已显示")
            fflush(stdout)
        }
    }
    
    private func toggleLoginItem() {
        // 防止重复点击
        isProcessingLoginSetting = true
        
        // 清除旧反馈
        actionFeedback = ""
        
        print("[调试] 切换开机启动设置")
        
        // 设置新状态
        let newValue = !settings.launchAtLogin
        settings.launchAtLogin = newValue
        
        // 短暂延迟后检查结果并更新UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let isSuccess = LaunchAtLogin.isEnabled == newValue
            
            // 更新反馈状态
            self.actionFeedback = isSuccess 
                ? "成功: 开机启动" + (newValue ? "已启用" : "已禁用") 
                : "失败: 请重试"
            
            print("[结果] \(self.actionFeedback)")
            fflush(stdout)
            
            // 完成处理
            self.isProcessingLoginSetting = false
        }
    }
} 