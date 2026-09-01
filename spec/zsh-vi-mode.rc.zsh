# vim:

#
#
# ~/.config/zsh/rc/plugin/zsh-vi-mode.rc.zsh
#
#

#
# TODO(@chewygumxx): (Priority: Medium) 
# This plugin is both incredibly valued and pervasively problematic.
# It defers setting of keybinds, overwriting anything I set in rc files
#
# It is worthwhile to fork and gut it of inconvienience.
#

function zvm_config() {
    # See https://github.com/jeffreytse/zsh-vi-mode#configuration-function
    
    ZVM_VI_HIGHLIGHT_BACKGROUND='#2d2857'
    ZVM_VI_HIGHLIGHT_FOREGROUND='#cad6ff'
    # ZVM_VI_HIGHLIGHT_EXTRASTYLE=bold,underline

    ZVM_CURSOR_STYLE_ENABLED=true
    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

    # ZVM_VI_SURROUND_BINDKEY
    # ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT

    ZVM_SYSTEM_CLIPBOARD_ENABLED=true
    ZVM_CLIPBOARD_COPY_CMD="wl-copy --trim-newline"
    ZVM_CLIPBOARD_PASTE_CMD="wl-paste --no-newline"

    ZVM_TMPDIR="$zsh_dirs[cache_zvm]"
    mkdir -p "$ZVM_TMPDIR"

    ZVM_OPEN_CMD="handlr open"
    ZVM_OPEN_URL_CMD="firefox --new-tab"
}


# https://github.com/jeffreytse/zsh-vi-mode#initialization-mode
#ZVM_INIT_MODE

# https://github.com/jeffreytse/zsh-vi-mode#initialization-mode
#ZVM_LAZY_KEYBINDINGS

# https://github.com/jeffreytse/zsh-vi-mode#custom-widgets-and-keybindings
# # Your custom widget
# function my_custom_widget() {
#   echo 'Hello, ZSH!'
# }
# 
# # The plugin will auto execute this zvm_after_lazy_keybindings function
# function zvm_after_lazy_keybindings() {
#   # Here we define the custom widget
#   zvm_define_widget my_custom_widget
# 
#   # In normal mode, press Ctrl-E to invoke this widget
#   zvm_bindkey vicmd '^E' my_custom_widget
# }

# https://github.com/jeffreytse/zsh-vi-mode#execute-extra-commands
#
# zvm_before_init_commands=()
# zvm_after_init_commands=()
# zvm_before_select_vi_mode_commands=()
# zvm_after_select_vi_mode_commands=()
# zvm_before_lazy_keybindings_commands=()
# zvm_after_lazy_keybindings_commands=()
#
# # Append a command directly
# zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')
#
# # Define an init function and append to zvm_after_init_commands
# function my_init() {
#   [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# }
# zvm_after_init_commands+=(my_init)
#
# # The plugin will auto execute this zvm_after_init function
# function zvm_after_init() {
#   [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# }
#
# # For postponing loading `fzf`
# zinit ice lucid wait
# zinit snippet OMZP::fzf
#
# # The plugin will auto execute this zvm_after_lazy_keybindings function
# function zvm_after_lazy_keybindings() {
#   bindkey -M vicmd 's' your_normal_widget
#   bindkey -M visual 'n' your_visual_widget
# }











