#
# ~/.bashrc
#

# Detect if running inside an integrated terminal of an editor (VS Code, Kiro, ZCode, Cursor, Windsurf, VSCodium, Positron, etc.)
is_editor_term=0
if [[ -n "$VSCODE_INJECTION" || -n "$VSCODE_PID" || -n "$ZCODE_PID" || -n "$ELECTRON_RUN_AS_NODE" ]]; then
  is_editor_term=1
elif [[ "$TERM_PROGRAM" =~ ^(vscode|kiro|cursor|windsurf|codium|zcode|positron) ]]; then
  is_editor_term=1
fi

if [[ $is_editor_term -eq 1 ]]; then
  # Inside editor terminal: prevent OS theme / COLORFGBG from leaking into editor CLI tools
  unset COLORFGBG
  unset GLAMOUR_STYLE
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [[ $is_editor_term -eq 1 ]]; then
  # Reset any OSC color overrides so terminal displays the editor's native theme
  printf '\033]110\033\\\033]111\033\\\033]112\033\\\033]104\033\\'
else
  # Standalone terminal (Kitty, Foot, etc.): apply dynamic OS terminal colors
  if [[ -f "$HOME/.local/state/quickshell/user/generated/terminal/colorfgbg.sh" ]]; then
    . "$HOME/.local/state/quickshell/user/generated/terminal/colorfgbg.sh"
  fi
  if [[ -f "$HOME/.local/state/quickshell/user/generated/terminal/sequences.txt" ]]; then
    cat "$HOME/.local/state/quickshell/user/generated/terminal/sequences.txt"
  fi
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path bash)"
