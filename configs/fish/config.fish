if status is-interactive
    # ── Useful abbreviations ──────────────────────────────────────────
    abbr -a ll  'ls -lah'
    abbr -a la  'ls -A'
    abbr -a g   'git'
    abbr -a gs  'git status'
    abbr -a gp  'git push'
    abbr -a gl  'git pull'
    abbr -a gc  'git commit -m'
    abbr -a lg  'lazygit'
    abbr -a nrs 'sudo nixos-rebuild switch --flake .#XyrelTenz'
    abbr -a v   'nvim'
    abbr -a cat 'bat'
    abbr -a ff  'fastfetch'
    abbr -a cd  'z'
    abbr -a zi  'z -i'
    abbr -a za  'zoxide add'
    abbr -a zr  'zoxide remove'
    abbr -a zq  'zoxide query'

    # ── Tool integrations ─────────────────────────────────────────────
    if command -v zoxide >/dev/null 2>&1
        zoxide init fish --cmd cd | source
    end
    if command -v fzf >/dev/null 2>&1
        set -e FZF_DEFAULT_OPTS
        fzf --fish | source
    end
    if command -v starship >/dev/null 2>&1
        starship init fish | source
    end

    # ── FZF Styling & Options ─────────────────────────────────────────
    set -gx FZF_DEFAULT_OPTS " \
      --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
      --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
      --color=marker:#b4befe,prompt:#cba6f7,query:#f38ba8 \
      --height 40% --layout=reverse --border=rounded --inline-info --prompt='❯ ' --pointer='▶' --marker='✓'"

    if command -v fd >/dev/null 2>&1
        set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
        set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
        set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
    else if command -v rg >/dev/null 2>&1
        set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git"'
        set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    end

    if command -v bat >/dev/null 2>&1
        set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window=right:60%:wrap"
    end
    if command -v eza >/dev/null 2>&1
        set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 {} 2>/dev/null' --preview-window=right:50%:wrap"
    end

    # ── Environment ───────────────────────────────────────────────────
    fish_add_path ~/.local/bin
    fish_add_path ~/.cargo/bin
    fish_add_path ~/Android/Sdk/cmdline-tools/latest/bin
    fish_add_path ~/Android/Sdk/emulator
    fish_add_path ~/Android/Sdk/platform-tools

    alias bun='env LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib:$LD_LIBRARY_PATH bun'
    alias npx='env LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib:$LD_LIBRARY_PATH npx'
    alias npm='env LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib:$LD_LIBRARY_PATH npm'
    alias yarn='env LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib:$LD_LIBRARY_PATH yarn'
    alias node='env LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib:$LD_LIBRARY_PATH node'

    set -x ANDROID_HOME ~/Android/Sdk
    set -x ANDROID_SDK_ROOT ~/Android/Sdk
    set -x ANDROID_AVD_HOME ~/.config/.android/avd

    set -x DIRENV_LOG_FORMAT ""

    set -x EDITOR nvim
    set -x VISUAL nvim
end

function fish_greeting
    ~/.config/fish/torii-greeting.sh
end
