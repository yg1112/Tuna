#!/usr/bin/env python3
import os
import re

# 配置
previews_dir = "docs/previews"
manifest_file = ".UISnapshotManifest"

# 确保manifest存在
if not os.path.exists(manifest_file):
    with open(manifest_file, "w") as f:
        f.write("# Tuna UI Snapshot Manifest\n\n")

# 读取当前manifest内容
with open(manifest_file, "r") as f:
    content = f.read()

# 获取所有截图
screenshots = []
for file in os.listdir(previews_dir):
    if file.endswith(".png"):
        component_name = file[:-4]  # 移除.png后缀
        screenshots.append((component_name, file))

# 更新manifest
updated_content = content

# 检查每个截图是否已添加到manifest
for component_name, filename in screenshots:
    # 构建图片引用
    pattern = r"!\[.*\].*" + re.escape(filename) + r".*"
    image_ref = f"![{component_name} Preview](docs/previews/{filename})"
    
    # 如果图片引用不存在，添加它
    if not re.search(pattern, content):
        # 尝试查找组件标题
        component_section = f"### {component_name}"
        
        if component_section in content:
            # 找到标题后插入图片引用
            updated_content = re.sub(
                f"{component_section}\n", 
                f"{component_section}\n{image_ref}\n\n", 
                updated_content
            )
        else:
            # 如果找不到组件标题，添加新部分
            updated_content += f"\n## {component_name}\n{image_ref}\n\n"

# 写回更新的内容
if updated_content != content:
    with open(manifest_file, "w") as f:
        f.write(updated_content)
    print(f"[SUCCESS] Updated {manifest_file} with new screenshot references")
else:
    print(f"[INFO] No changes needed for {manifest_file}")
