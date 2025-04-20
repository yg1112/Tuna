#!/usr/bin/env bash
defaults write ai.tuna.app dictationShortcutKeyCombo "opt+t"
killall Tuna 2>/dev/null
open -g Tuna.app
sleep 2
log stream --style compact --predicate 'subsystem=="ai.tuna" AND category=="Shortcut"' --timeout 5 