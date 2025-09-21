# If bat is not found, don't do the rest of the script
if (( ! $+commands[bat] )); then
  return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `bat`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_bat" ]]; then
  typeset -g -A _comps
  autoload -Uz _bat
  _comps[bat]=_bat
fi

bat --completion zsh >| "$ZSH_CACHE_DIR/completions/_bat" &|
