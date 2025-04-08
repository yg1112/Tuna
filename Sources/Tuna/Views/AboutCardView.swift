import SwiftUI
import Foundation

// 注意：tunaAccent 颜色已在 TunaSettingsView.swift 中定义，此处使用该定义

struct AboutCardView: View {
    // 图片状态
    @State private var catImage: NSImage?
    @State private var loadingAttempted = false
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧 - 图片部分
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.98, green: 0.98, blue: 0.98))
                    .frame(width: 400, height: 750)
                
                if let image = catImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 400, height: 750)
                        .clipped()
                        .overlay(
                            Rectangle()
                                .fill(Color.black.opacity(0.05))  // 轻微暗化图片
                        )
                } else if loadingAttempted {
                    // 图片加载失败时显示占位符
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                        
                        Text("Image not found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
            
            // 右侧 - 文本内容部分 - 宽度减小以平衡与左侧图片区域的视觉比例
            ZStack {
                // 主内容区 - 增加水平外边距给文本更多呼吸空间
                VStack(alignment: .leading) {
                    Spacer()
                    
                    Text("Why Tuna?")
                        .font(.title)  // 更大的标题尺寸 (24pt) 作为视觉锚点
                        .fontWeight(.semibold)  // 使用 semibold 而非 bold，更精致
                        .foregroundColor(Color(.labelColor))  // 使用系统标签颜色
                        .padding(.bottom, 32)  // 增加与下方段落的间距
                    
                    // 正文内容 - 增加行高、段落间距，以及更大的字体
                    VStack(alignment: .leading, spacing: 16) { // 增加段落间距为16pt
                        Text("Tuna was born from a very real moment.")
                            .font(.system(size: 16))  // 增加到16pt字体
                            .foregroundColor(Color(.labelColor))
                            .lineSpacing(6)  // 增加行高 (1.4倍行距)
                        
                        VStack(alignment: .leading, spacing: 10) { // 增加段落内句子间间距
                            Text("A warm, purring cat curled up in my arms.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                            
                            Text("And typing became impossible.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                        }
                        .padding(.bottom, 4)  // 微调段落之间的韵律
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("I realized: not every moment is made for keyboards.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                            
                            Text("But some of our best thoughts still live there.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                        }
                        .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("So Tuna listens quietly.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                            
                            Text("Transcribes faithfully.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                            
                            Text("Letting you keep cuddling, reading, sipping, thinking — and still keep your words.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                        }
                        .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Our cat loves Tuna.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                            
                            Text("We hope you will too.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.labelColor))
                                .lineSpacing(6)
                        }
                        
                        // 删除以下标语句，避免与底部版权信息重复
                        // VStack(spacing: 4) {
                        //     Text("Built with love.")
                        //         .font(.system(size: 14))
                        //         .foregroundColor(Color.tunaAccent.opacity(0.9))
                        //         .lineSpacing(5)
                        //     
                        //     Text("For makers like you.")
                        //         .font(.system(size: 14))
                        //         .foregroundColor(Color.tunaAccent.opacity(0.9))
                        //         .lineSpacing(5)
                        // }
                        // .frame(maxWidth: .infinity, alignment: .center)
                        // .padding(.top, 28)
                    }
                    
                    Spacer()
                    
                    // 底部版本信息放在右下角，使用更轻的颜色和更有品牌特色的文案
                    HStack {
                        Spacer()
                        
                        Text("© 2025 DZG Studio LLC · Designing with Zeal & Grace")
                            .font(.system(size: 10))  // 使用更小的字体，确保在所有常见窗口大小下不会被遮挡或省略
                            .foregroundColor(Color(.tertiaryLabelColor))  // 使用系统三级标签颜色
                            .padding(.top, 8) // 确保底部对齐
                    }
                }
                .padding(.horizontal, 32)  // 增加水平内边距到32pt
                .padding(.vertical, 24)    // 增加垂直内边距到24pt
            }
            .frame(width: 380, height: 750)  // 稍微减小宽度以与左侧图片区域取得视觉平衡
            .background(Color.white)
        }
        .frame(width: 780, height: 750)  // 总宽度相应调整
        .background(Color.white)
        .onAppear {
            loadImage()
        }
        // 确保在深色模式下文本保持可读性
        .environment(\.colorScheme, .light)
    }
    
    // 尝试加载图片
    private func loadImage() {
        // 尝试加载AboutImage.png
        let imagePath = "/Users/yukungao/github/tuna_v1/AboutImage.png"
        if let image = NSImage(contentsOfFile: imagePath) {
            self.catImage = image
            print("从本地路径加载图片成功")
        } else {
            print("无法加载图片，路径：\(imagePath)")
        }
        
        loadingAttempted = true
    }
}

// 使用标准的PreviewProvider代替#Preview宏
struct AboutCardView_Previews: PreviewProvider {
    static var previews: some View {
        AboutCardView()
    }
}