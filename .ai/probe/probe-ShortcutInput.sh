#!/usr/bin/env bash
# probe-ShortcutInput.sh
set -e
open -g Tuna.app
sleep 1
# 用 cliclick 让输入框获得焦点（假设有可访问性标签 "shortcutField"）
cliclick kp:tab
sleep 0.2
# 模拟 cmd+shift+o
cliclick kd:cmd kd:shift t:o ku:shift ku:cmd
sleep 0.2
# 读取 defaults 断言
v=$(defaults read ai.tuna.app dictationShortcutKeyCombo 2>/dev/null || true)
[[ "$v" == "cmd+shift+o" ]]
echo "✓ capture ok"
# 测试退格
cliclick kp:backspace
sleep 0.2
v=$(defaults read ai.tuna.app dictationShortcutKeyCombo 2>/dev/null || true)
[[ -z "$v" ]] && echo "✓ delete ok" 