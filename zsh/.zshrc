# ~/.zshrc

# --------
# Basics
# --------
export EDITOR=nano
export VISUAL=nano
export PAGER=less
export LESS='-R'
export LANG=de_DE.UTF-8
export PATH="$HOME/.local/bin:$PATH"

# --------
# History
# --------
HISTFILE=~/.zsh_history
HISTSIZE=20000
SAVEHIST=20000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# --------
# Completion
# --------
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zmodload zsh/complist

# --------
# Useful keybinds
# --------
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# --------
# FZF
# --------
if command -v fzf >/dev/null 2>&1; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
  source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
fi

# --------
# zoxide
# --------
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# --------
# starship prompt
# --------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# --------
# Syntax highlighting / autosuggestions
# --------
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# --------
# Better defaults
# --------
alias ls='eza --icons'
alias ll='eza -lah --icons --group-directories-first'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'
alias cat='batcat'
# alias grep='rg'
# alias find='fdfind'
alias du='du -h'
alias df='df -h'
alias free='free -h'
alias cls='clear'
alias c='clear'
alias q='exit'

# --------
# Git aliases
# --------
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias lg='lazygit'

# --------
# Navigation helpers
# --------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# --------
# Safer file operations
# --------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# --------
# Quick system shortcuts
# --------
alias update='sudo apt update && sudo apt full-upgrade'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias purge='sudo apt purge'
alias search='apt search'

# --------
# Bat styling
# --------
export BAT_THEME="TwoDark"

# --------
# Custom functions
# --------

mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.rar)     unrar x "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *) echo "Kann Archivtyp nicht entpacken: $1" ;;
    esac
  else
    echo "Datei nicht gefunden: $1"
  fi
}

# --------
# PATH additions
# --------
# export PATH="$HOME/.local/bin:$PATH"

# # SwirlDesk terminal splash
# case $- in
#     *i*)
#         if [ -n "$KITTY_WINDOW_ID" ] && [ -z "$SWIRLDESK_SPLASH_SHOWN" ]; then
#             export SWIRLDESK_SPLASH_SHOWN=1
#             clear
#             fastfetch
#             echo
#         fi
#         ;;
# esac
#
# if [ -n "$KITTY_WINDOW_ID" ] && [ -z "$SWIRLDESK_SPLASH_SHOWN" ]; then
#     export SWIRLDESK_SPLASH_SHOWN=1
#     clear
#     swirlfetch
#     echo
# fi
# SwirlDesk splash in kitty
case $- in
    *i*)
        if [ -n "$KITTY_WINDOW_ID" ] && [ -z "$SWIRLDESK_SPLASH_SHOWN" ]; then
            export SWIRLDESK_SPLASH_SHOWN=1
            clear
            if command -v swirlfetch >/dev/null 2>&1; then
                swirlfetch
                echo
            fi
        fi
        ;;
esac
