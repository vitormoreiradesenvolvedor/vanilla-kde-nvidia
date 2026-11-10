# PATH para ferramentas instaladas por usuario (brew, nix, cargo, sdkman)
_devtools_path_add() { case ":$PATH:" in *":$1:"*) ;; *) [ -d "$1" ] && PATH="$1:$PATH" ;; esac; }

_devtools_path_add /nix/var/nix/profiles/default/bin
_devtools_path_add "$HOME/.nix-profile/bin"
_devtools_path_add "$HOME/.cargo/bin"
_devtools_path_add "$HOME/.local/bin"
export PATH

if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [ -z "${SDKMAN_DIR:-}" ] && [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    export SDKMAN_DIR="$HOME/.sdkman"
    . "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
unset -f _devtools_path_add
