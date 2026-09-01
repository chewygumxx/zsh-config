# vim: expandtab:shiftwidth=4:textwidth=100

#
#
# ~/.config/zsh/prompt.rc.zsh
#
#

#
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
# https://zsh.sourceforge.io/Doc/Release/Parameters.html#index-PROMPT
# https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell-1
#

autoload -Uz add-zsh-hook

unsetopt single_line_zle  # For >>Right PS1

setopt prompt_subst       # Prompt subject to parameter expansion, command
                          # substitution, and arithmetic expansion

setopt prompt_percent     # %-Based escape sequences



# Escape sequences must be enclosed within `%{...%}` such that cursor position calculation is
# not affected by zero width sequences
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Visual-effects

() {
    local blink="%{"$'\e[5m'"%}"
    local none="%{"$'\e[0m'"%}"

    local clock=(
        "%F{#626262}[%f"
        "%F{#5f95fa}%D{%H}%f"
        "%F{#7171d3}:%f"
        "%F{#5f95fa}%D{%M}%f"
        "%F{#7171d3}:%f"
        "%F{#5f95fa}%D{%S}%f"
        "%F{#626262}]%f"
    )
    local caret_privilege=(
        "%(#."                              # If user is root
            $blink "%F{red}%#%f" $none      #   Caret is a blinking red '#'
        "."                                 # Else
            "%F{#4db380}>%f"                #   Caret is green '>'
        ")"
    )
    local shell_level="%(2L.%F{#ec5f66} <%L>%f.)"
    local curr_work_dir=" %F{magenta}%(#.%d.%~)%f"   # If root, /absolute/path, otherwise ~named/path
    local background_jobs="%(1j.%F{2} [%B%j%b].)"
    local exit_code="%(?..%F{red}%B %?%b%f)"        # Exit Code (if not zero)

    local -a __ps1_mods=( 
        "${(j::)clock}"

        "$shell_level"
        "$curr_work_dir"

        "$background_jobs"
        "$exit_code"
        "${(j::)caret_privilege}"
    )

    PS1="${(j::)__ps1_mods}"
}


function __preexec_rps1() {
    time_invoked=$SECONDS
}
add-zsh-hook preexec __preexec_rps1

function __format_duration() {
    local total=$1
    local h=$(( total / 3600 ))
    local m=$(( (total % 3600) / 60 ))
    local s=$(( total % 60 ))

    if (( h > 0 )); then
        printf '%dh %dm %ds' "$h" "$m" "$s"
    elif (( m > 0 )); then
        printf '%dm %ds' "$m" "$s"
    else
        printf '%ds' "$s"
    fi
}

function __precmd_rps1() {
    RPS1=""

    if [[ -n $time_invoked ]]; then
        local time_exec=$(( $SECONDS - $time_invoked ))
        if [[ $time_exec -gt 10 ]]; then
            RPS1="%F{blue}$(__format_duration $time_exec)%f"
        fi
        unset time_invoked
    fi
}
add-zsh-hook precmd __precmd_rps1
