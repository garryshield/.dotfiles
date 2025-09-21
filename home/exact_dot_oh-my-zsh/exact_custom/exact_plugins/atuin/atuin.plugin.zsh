# If atuin is not found, don't do the rest of the script
if (( ! $+commands[atuin] )); then
  return
fi

# If the completion file doesn't exist yet, we need to autoload it and
# bind it to `atuin`. Otherwise, compinit will have already done that.
if [[ ! -f "$ZSH_CACHE_DIR/completions/_atuin" ]]; then
  typeset -g -A _comps
  autoload -Uz _atuin
  _comps[atuin]=_atuin
fi

atuin gen-completions --shell zsh >| "$ZSH_CACHE_DIR/completions/_atuin" &|