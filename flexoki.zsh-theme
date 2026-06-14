# ~/.oh-my-zsh/custom/themes/flexoki.zsh-theme
# Flexoki-Dark minimalist prompt implementation

# Hook into Git status architectures natively supported by OMZ
ZSH_THEME_GIT_PROMPT_PREFIX="%F{8}(%F{3}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{8}) "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{1}⚡%F{3}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

function prompt_status() {
  # Return an inky red indicator if the previous system command returned a non-zero exit code
  echo "%(?.%F{2}+.%F{1}✕)%f"
}

# Constructing the Master Layout:
# [Status] [Directory Path in Flexoki Blue] [Git Branch Context]
PROMPT='%F{#66800B}$USER%F{#878580}@%F{#A02F6F}$HOST %F{#205EA6}%~%f $(git_prompt_info)%F{66800B}❯%f '
