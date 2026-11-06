#!/bin/false
# vim:set expandtab shiftwidth=4 filetype=zsh:
# SPDX-License-Identifier: GPL-3.0-only

#
#
# ~chewygumxx/zsh-config.git
# ::: :/tests/_support/nvim.zsh
#
#

function nvim_background_probe() {
    emulate -L zsh
    zmodload zsh/zpty || return 1

    local root="$1" mode="$2"
    local cache="$root/cache/zsh/nvim/chezmoi-managed"
    local worker=0 worker_group=0 result=1 i

    mkdir -p -- "$root/bin" "$root/home/managed" "$root/config" \
        "$root/src" "${cache:h}"
    touch -- "$root/home/managed/file"
    print -r -- "$root/src" > "$cache.source"
    print -rl -- "$root/home/managed" "$root/home/managed/file" > "$cache"
    touch -d 2000-01-01 -- "$root/src"
    [[ "$mode" == refresh* ]] && command rm -- "$cache"

    cat > "$root/bin/nvim" << 'EOF'
#!/bin/sh
touch "$1"
EOF
    cat > "$root/bin/chezmoi" << 'EOF'
#!/bin/sh
if [ "$1" = source-path ]; then
    printf '%s\n' "$CASE_ROOT/src"
    exit
fi
printf '%s\n' "$1" >> "$CASE_ROOT/calls"
exec 8> "$CASE_ROOT/db.lock"
flock 8
printf '%s\n' "$$" > "$CASE_ROOT/pid"
ps -p "$$" -o pgid= >> "$CASE_ROOT/groups"
case "$CASE_MODE" in
    refresh-once|serialize)
        while [ ! -e "$CASE_ROOT/release" ]; do sleep 0.02; done
        printf '%s\n' "$CASE_ROOT/home/managed/file"
        ;;
    hang) trap '' TERM; sleep 30 ;;
    orphan)
        (trap '' TERM; sleep 30) &
        wait "$!"
        ;;
    daemon)
        (exec 8>&-; sleep 3) &
        ;;
    *)
        if read -r answer < /dev/tty; then
            printf 'unexpected terminal input\n' >&2
        else
            printf 'detached\n' > "$CASE_ROOT/done"
            printf 'terminal unavailable\n' >&2
        fi
        ;;
esac
EOF
    chmod 0755 -- "$root/bin/nvim" "$root/bin/chezmoi"

    cat > "$root/driver.zsh" << 'EOF'
fpath=("$CASE_RUNTIME/wrap" $fpath)
autoload -Uz nvim
if [[ "$CASE_MODE" == serialize ]]; then
    flock "$XDG_CACHE_HOME/zsh/nvim/chezmoi.lock" sh -c \
        'touch "$CASE_ROOT/held"; sleep 0.7' &!
    while [[ ! -e "$CASE_ROOT/held" ]]; do sleep 0.02; done
fi
if [[ "$CASE_MODE" == add ]]; then
    nvim "$CASE_ROOT/home/managed/new" <<< y
else
    nvim "$CASE_ROOT/home/managed/file"
fi
if [[ "$CASE_MODE" == refresh-once || "$CASE_MODE" == serialize || "$CASE_MODE" == daemon ]]; then
    nvim "$CASE_ROOT/home/managed/file"
fi
print -r -- returned > "$CASE_ROOT/returned"
read -r answer
EOF

    {
        zpty -b nvim_probe env -i \
            HOME="$root/home" ZDOTDIR="$root/config" \
            XDG_CONFIG_HOME="$root/config" XDG_CACHE_HOME="$root/cache" \
            XDG_DATA_HOME="$root/data" XDG_STATE_HOME="$root/state" \
            PATH="$root/bin:/usr/bin:/bin" \
            CASE_ROOT="$root" CASE_MODE="$mode" \
            CASE_RUNTIME="$ZSH_CONFIG_ROOT" NVIM_CHEZMOI_TIMEOUT=0.3s \
            zsh -dfi "$root/driver.zsh" || return 1

        for i in {1..100}; do
            [[ -s "$root/pid" && -s "$root/returned" ]] && break
            sleep 0.02
        done
        if [[ -s "$root/pid" ]]; then
            worker="$(< "$root/pid")"
            worker_group="$(command ps -p "$worker" -o pgid=)" || true
        fi

        if [[ "$mode" == refresh-once || "$mode" == serialize ]]; then
            # Both editor calls returned while the first refresh is pending.
            sleep 0.1
            [[ -s "$root/calls" ]] && result="$(wc -l < "$root/calls")"
            touch -- "$root/release"
            if [[ "$mode" == refresh-once ]]; then
                for i in {1..100}; do
                    [[ -s "$cache" ]] && break
                    sleep 0.02
                done
                [[ "$result" -eq 1 && -s "$cache" ]] && result=0 || result=1
            else
                for i in {1..100}; do
                    [[ "$(wc -l < "$root/calls")" -eq 2 ]] && break
                    sleep 0.02
                done
                [[ "$result" -eq 1 && "$(wc -l < "$root/calls")" -eq 2 ]] &&
                    result=0 || result=1
            fi
        elif [[ "$mode" == daemon ]]; then
            for i in {1..50}; do
                [[ "$(wc -l < "$root/calls")" -eq 2 ]] && break
                sleep 0.02
            done
            [[ "$(wc -l < "$root/calls")" -eq 2 ]] && result=0
        elif [[ "$mode" == hang || "$mode" == orphan ]]; then
            for i in {1..350}; do
                [[ -s "$root/pid" ]] &&
                    command flock -n "$root/db.lock" true && break
                sleep 0.02
            done
            command flock -n "$root/db.lock" true &&
                [[ -s "${cache:h}/chezmoi.log" ]] && result=0
        else
            for i in {1..100}; do
                [[ -s "$root/done" ]] &&
                    command flock -n "$root/db.lock" true && break
                sleep 0.02
            done
            [[ -s "$root/done" ]] &&
                command flock -n "$root/db.lock" true &&
                command grep -q 'terminal unavailable' "${cache:h}/chezmoi.log" &&
                result=0
        fi
    } always {
        # The unfixed wrapper leaves a stopped, disowned process group.
        # Kill only the group recorded by this fixture before closing its pty.
        if [[ "$worker_group" -gt 0 ]]; then
            kill -KILL -- -${worker_group// /} 2> /dev/null || true
        fi
        if [[ -s "$root/groups" ]]; then
            local group
            for group in "${(@f)$(<"$root/groups")}"; do
                kill -KILL -- -${group// /} 2> /dev/null || true
            done
        fi
        zpty -d nvim_probe 2> /dev/null || true
    }

    return "$result"
}
