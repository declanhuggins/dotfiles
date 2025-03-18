export ZSH="$HOME/.oh-my-zsh"

if [ -f ~/.env ]; then
    export $(grep -v '^#' ~/.env | xargs)
fi

ZSH_THEME="darkblood"
zstyle ':omz:update' mode auto
plugins=(git)
source $ZSH/oh-my-zsh.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/hugs/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/hugs/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/hugs/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/hugs/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

alias whisperx-run="~/Scripts/whisperx-run.sh"
alias disable-sleep='sudo pmset -a disablesleep 1'
alias enable-sleep='sudo pmset -a disablesleep 0'
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
alias deepseek-tiny="ollama serve > /dev/null 2>&1 & ollama run deepseek-r1:1.5b"
alias deepseek="ollama serve > /dev/null 2>&1 & ollama run deepseek-r1:8b"
alias deepseek-large="ollama serve > /dev/null 2>&1 & ollama run deepseek-r1:14b"