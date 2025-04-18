#!/usr/bin/env python3
import os
import re
import sys

# 配置
previews_dir = "docs/previews"
manifest_file = ".UISnapshotManifest.md"

# 确定哪些是Tuna应用的实际组件截图
tuna_ui_components = [
    "MenuBarView",
    "TunaDictationView",
    "QuickDictationView",
    "AboutCardView",
    "TunaSettingsView",
    "BidirectionalSlider",
    "ShortcutTextField",
    "GlassCard",
    "ModernToggleStyle"
]

# 检查图片文件是否存在
missing_images = []
for component in tuna_ui_components:
    filename = f"{component}.png"
    filepath = os.path.join(previews_dir, filename)
    if not os.path.exists(filepath):
        missing_images.append(filename)
        print(f"⚠️ 缺少UI组件截图: {filename}")
    else:
        # 检查文件大小，确保不是空文件
        file_size = os.path.getsize(filepath)
        if file_size < 1000:  # 小于1KB可能是空白或无效图片
            print(f"⚠️ 图片文件过小，可能是无效图片: {filename} ({file_size} 字节)")
        else:
            print(f"✅ 找到UI组件截图: {filename} ({file_size} 字节)")

if missing_images:
    print(f"\n警告: 缺少 {len(missing_images)} 个UI组件截图！")
    for img in missing_images:
        print(f"  - {img}")
    print("\n请运行UI测试生成这些截图: swift test --filter UISnapshots\n")

# 读取manifest文件
try:
    with open(manifest_file, "r", encoding="utf-8") as f:
        manifest_content = f.read()
except Exception as e:
    print(f"错误: 无法读取manifest文件 '{manifest_file}': {e}")
    sys.exit(1)

# 检查组件在manifest中的引用
print("\n检查组件在manifest中的引用...")
missing_references = []
for component in tuna_ui_components:
    filename = f"{component}.png"
    ref_pattern = f"\\!\\[{component}(预览|Preview)\\]\\(docs/previews/{filename}\\)"
    
    if re.search(ref_pattern, manifest_content):
        print(f"✅ 组件在manifest中已正确引用: {component}")
    else:
        # 尝试查找不同形式的引用格式
        alt_patterns = [
            f"\\!\\[.*\\]\\(docs/previews/{filename}\\)",  # 任意alt文本
            f"\\!\\[.*{component}.*\\]\\(docs/previews/.*\\)",  # 部分匹配alt文本
            f"\\!\\[.*\\]\\(.*{filename}\\)"  # 任意路径但正确文件名
        ]
        
        found = False
        for pattern in alt_patterns:
            if re.search(pattern, manifest_content):
                print(f"⚠️ 组件在manifest中有引用，但格式可能不标准: {component}")
                found = True
                break
                
        if not found:
            missing_references.append(component)
            print(f"❌ 组件在manifest中缺少引用: {component}")

# 如果有缺少的引用，添加它们
if missing_references:
    print(f"\n发现 {len(missing_references)} 个缺少引用的组件，正在添加...")
    
    for component in missing_references:
        filename = f"{component}.png"
        image_ref = f"\n## {component}\n![{component}预览](docs/previews/{filename})\n\n"
        manifest_content += image_ref
        print(f"➕ 已添加引用: {component}")
    
    # 写回更新后的manifest
    try:
        with open(manifest_file, "w", encoding="utf-8") as f:
            f.write(manifest_content)
        print(f"\n✅ 已更新manifest文件: {manifest_file}")
    except Exception as e:
        print(f"错误: 无法写入manifest文件 '{manifest_file}': {e}")
        sys.exit(1)
else:
    print("\n✅ 所有UI组件在manifest中都有正确引用！")

print("\n完成UI截图验证！") 