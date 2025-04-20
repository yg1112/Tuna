#!/usr/bin/env python3
import os
import sys
from pathlib import Path
import json
import re

def get_file_content(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"Warning: Could not read {file_path}: {e}")
        return ""

def write_file(file_path, content):
    # Only create directories if the path has a directory component
    dir_path = os.path.dirname(file_path)
    if dir_path:
        os.makedirs(dir_path, exist_ok=True)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def generate_context():
    workspace_root = Path.cwd()
    
    # Files to always include
    important_files = [
        'Package.swift',
        'Package.resolved',
        'requirements.txt',
        'pyproject.toml',
        'Cargo.toml',
        'package.json',
        '.cursor/rules',
        'README.md'
    ]
    
    # Directories to scan for source files
    source_dirs = [
        'Sources',
        'src',
        'app',
        'lib',
        'tests',
        'Tests'
    ]
    
    # File extensions to include
    source_extensions = {'.swift', '.py', '.js', '.ts', '.go', '.rs', '.java'}
    
    context = []
    
    # Add important files
    for file_path in important_files:
        full_path = workspace_root / file_path
        if full_path.exists():
            content = get_file_content(full_path)
            if content:
                context.append(f"# {file_path}\n```\n{content}\n```\n")
    
    # Add source files
    for dir_name in source_dirs:
        dir_path = workspace_root / dir_name
        if dir_path.exists():
            for file_path in dir_path.rglob('*'):
                if file_path.suffix in source_extensions:
                    rel_path = file_path.relative_to(workspace_root)
                    content = get_file_content(file_path)
                    if content:
                        context.append(f"# {rel_path}\n```\n{content}\n```\n")
    
    # Generate the full context
    full_context = "# Project Context\n\n" + "\n".join(context)
    
    # Generate a snapshot for ChatGPT (shorter version)
    gpt_snapshot = "# Project Overview\n\nThis is a snapshot of key project files and structure.\n\n"
    gpt_snapshot += "\n".join(context[:5])  # First 5 files only
    
    # Write outputs
    write_file('.cursorscratchpad', full_context)
    write_file('docs/GPT_CONTEXT.md', gpt_snapshot)

if __name__ == '__main__':
    generate_context() 