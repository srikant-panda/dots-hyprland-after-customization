# Terminal mode environment (COLORFGBG, GLAMOUR_STYLE)
if test -f ~/.local/state/quickshell/user/generated/terminal/colorfgbg.fish
    source ~/.local/state/quickshell/user/generated/terminal/colorfgbg.fish
end

# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Disable autosuggestions
    set -g fish_autosuggestion_enabled 0

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Terminal escape sequences for live colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end

eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)

string match -q "$TERM_PROGRAM" "kiro" and . (kiro --locate-shell-integration-path fish)
