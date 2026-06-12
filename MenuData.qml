import QtQuick

QtObject {
    readonly property var items: [
        { name: "Apps", icon: "󰀻", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call launcher toggle" },
        { name: "Learn", icon: "󰧑", sub: [
            { name: "Keybindings", icon: "", keybindings: true },
            { name: "Omarchy", icon: "", command: "omarchy-launch-webapp https://learn.omacom.io/2/the-omarchy-manual" },
            { name: "Hyprland", icon: "", command: "omarchy-launch-webapp https://wiki.hypr.land/" },
            { name: "Arch", icon: "󰣇", command: "omarchy-launch-webapp https://wiki.archlinux.org/title/Main_page" },
            { name: "Bash", icon: "󱆃", command: "omarchy-launch-webapp https://devhints.io/bash" },
            { name: "Neovim", icon: "", command: "omarchy-launch-webapp https://www.lazyvim.org/keymaps" }
        ]},
        { name: "Trigger", icon: "󱓞", sub: [
            { name: "Reminder", icon: "󰔛", sub: [
                { name: "Set one", icon: "󰔛", command: "omarchy-menu reminder-set" },
                { name: "Show all", icon: "󰔛", command: "omarchy-reminder show" },
                { name: "Clear all", icon: "󰔛", command: "omarchy-reminder clear" }
            ]},
            { name: "Capture", icon: "", sub: [
                { name: "Screenshot", icon: "", command: "omarchy-capture-screenshot" },
                { name: "Record", icon: "", sub: [
                    { name: "No Audio", icon: "", command: "omarchy-capture-screenrecording" },
                    { name: "Desktop", icon: "", command: "omarchy-capture-screenrecording --with-desktop-audio" },
                    { name: "Mic", icon: "", command: "omarchy-capture-screenrecording --with-desktop-audio --with-microphone-audio" },
                    { name: "Webcam", icon: "", command: "omarchy-capture-screenrecording --with-desktop-audio --with-microphone-audio --with-webcam" }
                ]},
                { name: "Text", icon: "󰴑", command: "omarchy-capture-text-extraction" },
                { name: "Color", icon: "󰃉", command: "hyprpicker -a" }
            ]},
            { name: "Transcode", icon: "󰧸", command: "omarchy-transcode" },
            { name: "Share", icon: "", sub: [
                { name: "Clipboard", icon: "", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call clipboard toggle" },
                { name: "File", icon: "", command: "xdg-terminal-exec bash -c omarchy-menu-share file" },
                { name: "Folder", icon: "", command: "xdg-terminal-exec bash -c omarchy-menu-share folder" }
            ]},
            { name: "Toggle", icon: "󰔎", sub: [
                { name: "Screensaver", icon: "󱄄", command: "omarchy-toggle-screensaver" },
                { name: "Nightlight", icon: "󰔎", command: "omarchy-toggle-nightlight" },
                { name: "Idle Lock", icon: "󱫖", command: "omarchy-toggle-idle" },
                { name: "Notifications", icon: "󰂛", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call notifications toggle" },
                { name: "Top Bar", icon: "󰍜", command: "omarchy-toggle-waybar" },
                { name: "Workspace Layout", icon: "󱂬", command: "omarchy-hyprland-workspace-layout-toggle" },
                { name: "Window Gaps", icon: "", command: "omarchy-hyprland-window-gaps-toggle" },
                { name: "1-Window Ratio", icon: "", command: "omarchy-hyprland-window-single-square-aspect-toggle" },
                { name: "Monitor Scaling", icon: "󰍹", command: "omarchy-hyprland-monitor-scaling-cycle" },
                { name: "Direct Boot", icon: "", command: "xdg-terminal-exec omarchy-config-direct-boot" },
                { name: "Passwordless Sudo", icon: "󰟵", command: "xdg-terminal-exec omarchy-sudo-passwordless" }
            ]},
            { name: "Hardware", icon: "", sub: [
                { name: "Laptop Display", icon: "󰛧", command: "omarchy-hyprland-monitor-internal toggle" },
                { name: "Mirror Display", icon: "󰍹", command: "omarchy-hyprland-monitor-internal-mirror toggle" },
                { name: "Hybrid GPU", icon: "", command: "xdg-terminal-exec omarchy-toggle-hybrid-gpu" },
                { name: "Touchpad", icon: "󰟸", command: "omarchy-toggle-touchpad" },
                { name: "Touchpad Haptics", icon: "󰌌", command: "omarchy-menu hardware-touchpad-haptics" },
                { name: "Touchscreen", icon: "󰆽", command: "omarchy-toggle-touchscreen" }
            ]}
        ]},
        { name: "Style", icon: "", sub: [
            { name: "Theme", icon: "󰸌", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call style theme" },
            { name: "Font", icon: "", dynamic: { cmd: "omarchy font list", icon: "", prefix: "omarchy font set" } },
            { name: "Background", icon: "", sub: [
                { name: "Choose", icon: "", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call style wallpaper" },
                { name: "Next", icon: "", command: "omarchy theme bg next" },
                { name: "Open Folder", icon: "", command: "omarchy theme bg install" }
            ]},
            { name: "Theme Tools", icon: "󰒓", sub: [
                { name: "Current Theme", icon: "󰸌", command: "xdg-terminal-exec omarchy theme current" },
                { name: "Refresh Current", icon: "", command: "omarchy theme refresh && quickshell kill --path ~/.config/quickshell/shell.qml; quickshell --path ~/.config/quickshell/shell.qml --daemonize" },
                { name: "Install Theme", icon: "󰉉", command: "xdg-terminal-exec omarchy theme install" },
                { name: "Remove Theme", icon: "󰭌", command: "xdg-terminal-exec omarchy theme remove" },
                { name: "Update Themes", icon: "󰚰", command: "xdg-terminal-exec omarchy theme update" }
            ]},
            { name: "Hyprland", icon: "", command: "omarchy-launch-editor ~/.config/hypr/looknfeel.conf" },
            { name: "Screensaver", icon: "󱄄", sub: [
                { name: "Edit Text", icon: "", command: "omarchy-branding-screensaver text" },
                { name: "Set From Image", icon: "", command: "omarchy-branding-screensaver image" },
                { name: "Restore Default", icon: "", command: "omarchy-branding-screensaver reset" }
            ]},
            { name: "About", icon: "", sub: [
                { name: "Edit Text", icon: "", command: "omarchy-branding-about text" },
                { name: "Set From Image", icon: "", command: "omarchy-branding-about image" },
                { name: "Restore Default", icon: "", command: "omarchy-branding-about reset" }
            ]}
        ]},
        { name: "Setup", icon: "", sub: [
            { name: "Audio", icon: "", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call audio toggle" },
            { name: "Wifi", icon: "", command: "omarchy-launch-wifi" },
            { name: "Bluetooth", icon: "󰂯", command: "omarchy-launch-bluetooth" },
            { name: "Power", icon: "󱐋", dynamic: { cmd: "powerprofilesctl list | grep -o '^  [a-z-]*' | sed 's/^  //'", icon: "󱐋", prefix: "powerprofilesctl set" } },
            { name: "System Sleep", icon: "", sub: [
                { name: "Suspend", icon: "󰒲", command: "omarchy-toggle-suspend" },
                { name: "Hibernate (Enable)", icon: "󰤁", command: "xdg-terminal-exec omarchy-hibernation-setup" },
                { name: "Hibernate (Disable)", icon: "󰤁", command: "xdg-terminal-exec omarchy-hibernation-remove" }
            ]},
            { name: "Monitors", icon: "󰍹", command: "omarchy-launch-editor ~/.config/hypr/monitors.conf" },
            { name: "Keybindings", icon: "", command: "omarchy-launch-editor ~/.config/hypr/bindings.conf" },
            { name: "Input", icon: "", command: "omarchy-launch-editor ~/.config/hypr/input.conf" },
            { name: "Defaults", icon: "", sub: [
                { name: "Browser", icon: "", dynamic: { cmd: "for b in chromium google-chrome brave-browser brave-origin-beta microsoft-edge firefox zen; do [ -f /usr/share/applications/$b.desktop ] || [ -f ~/.local/share/applications/$b.desktop ] && echo $b; done", icon: "", prefix: "omarchy-default-browser" } },
                { name: "Terminal", icon: "", dynamic: { cmd: "for t in alacritty foot ghostty kitty; do which $t >/dev/null 2>&1 && echo $t; done", icon: "", prefix: "omarchy-default-terminal" } },
                { name: "Editor", icon: "", dynamic: { cmd: "for e in nvim code cursor zeditor sublime_text helix vim emacs; do which $e >/dev/null 2>&1 && echo $e; done", icon: "", prefix: "omarchy-default-editor" } }
            ]},
            { name: "DNS", icon: "󰱔", command: "xdg-terminal-exec omarchy-setup-dns" },
            { name: "Security", icon: "", sub: [
                { name: "Fingerprint", icon: "󰈷", command: "xdg-terminal-exec omarchy-setup-security-fingerprint" },
                { name: "Fido2", icon: "", command: "xdg-terminal-exec omarchy-setup-security-fido2" }
            ]},
            { name: "Config", icon: "", sub: [
                { name: "Hyprland", icon: "", command: "omarchy-launch-editor ~/.config/hypr/hyprland.conf" },
                { name: "Hypridle", icon: "", command: "omarchy-launch-editor ~/.config/hypr/hypridle.conf" },
                { name: "Hyprlock", icon: "", command: "omarchy-launch-editor ~/.config/hypr/hyprlock.conf" },
                { name: "Hyprsunset", icon: "", command: "omarchy-launch-editor ~/.config/hypr/hyprsunset.conf" },
                { name: "Swayosd", icon: "", command: "omarchy-launch-editor ~/.config/swayosd/config.toml" },
                { name: "Walker", icon: "󰌧", command: "omarchy-launch-editor ~/.config/walker/config.toml" },
                { name: "Waybar", icon: "󰍜", command: "omarchy-launch-editor ~/.config/waybar/config.jsonc" },
                { name: "XCompose", icon: "󰞅", command: "omarchy-launch-editor ~/.XCompose" }
            ]}
        ]},
        { name: "Install", icon: "󰉉", sub: [
            { name: "Package", icon: "󰣇", command: "xdg-terminal-exec omarchy-pkg-install" },
            { name: "AUR", icon: "󰣇", command: "xdg-terminal-exec omarchy-pkg-aur-install" },
            { name: "Web App", icon: "", command: "xdg-terminal-exec omarchy-webapp-install" },
            { name: "TUI", icon: "", command: "xdg-terminal-exec omarchy-tui-install" },
            { name: "Service", icon: "", sub: [
                { name: "Dropbox", icon: "", command: "xdg-terminal-exec omarchy-install-dropbox" },
                { name: "Tailscale", icon: "", command: "xdg-terminal-exec omarchy-install-tailscale" },
                { name: "NordVPN", icon: "󱇱", command: "xdg-terminal-exec omarchy-install-nordvpn" },
                { name: "ONCE", icon: "󰏖", command: "xdg-terminal-exec omarchy-install-once" },
                { name: "Bitwarden", icon: "󰟵", command: "xdg-terminal-exec bash -c \"echo 'Installing Bitwarden...'; omarchy-pkg-add bitwarden bitwarden-cli && setsid gtk-launch bitwarden\"" },
                { name: "Chromium Account", icon: "", command: "xdg-terminal-exec omarchy-install-chromium-google-account" }
            ]},
            { name: "Style", icon: "", sub: [
                { name: "Theme", icon: "󰸌", command: "xdg-terminal-exec omarchy-theme-install" },
                { name: "Background", icon: "", command: "omarchy-theme-bg-install" },
                { name: "Font", icon: "", sub: [
                    { name: "Cascadia Mono", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add ttf-cascadia-mono-nerd && sleep 2 && omarchy-font-set 'CaskaydiaMono Nerd Font'\"" },
                    { name: "Meslo LG Mono", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add ttf-meslo-nerd && sleep 2 && omarchy-font-set 'MesloLGL Nerd Font'\"" },
                    { name: "Fira Code", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add ttf-firacode-nerd && sleep 2 && omarchy-font-set 'FiraCode Nerd Font'\"" },
                    { name: "Victor Code", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add ttf-victor-mono-nerd && sleep 2 && omarchy-font-set 'VictorMono Nerd Font'\"" },
                    { name: "Bitstream Vera", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add ttf-bitstream-vera-mono-nerd && sleep 2 && omarchy-font-set 'BitstromWera Nerd Font'\"" },
                    { name: "Iosevka", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add ttf-iosevka-nerd && sleep 2 && omarchy-font-set 'Iosevka Nerd Font Mono'\"" }
                ]}
            ]},
            { name: "Development", icon: "󰵮", sub: [
                { name: "Ruby on Rails", icon: "󰫏", command: "xdg-terminal-exec omarchy-install-dev-env ruby" },
                { name: "JavaScript", icon: "", sub: [
                    { name: "Node.js", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env node" },
                    { name: "Bun", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env bun" },
                    { name: "Deno", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env deno" }
                ]},
                { name: "Go", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env go" },
                { name: "PHP", icon: "", sub: [
                    { name: "PHP", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env php" },
                    { name: "Laravel", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env laravel" },
                    { name: "Symfony", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env symfony" }
                ]},
                { name: "Python", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env python" },
                { name: "Elixir", icon: "", sub: [
                    { name: "Elixir", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env elixir" },
                    { name: "Phoenix", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env phoenix" }
                ]},
                { name: "Zig", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env zig" },
                { name: "Rust", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env rust" },
                { name: "Java", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env java" },
                { name: ".NET", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env dotnet" },
                { name: "OCaml", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env ocaml" },
                { name: "Clojure", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env clojure" },
                { name: "Scala", icon: "", command: "xdg-terminal-exec omarchy-install-dev-env scala" }
            ]},
            { name: "Editor", icon: "", sub: [
                { name: "VSCode", icon: "", command: "xdg-terminal-exec omarchy-install-vscode" },
                { name: "Cursor", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add cursor-bin && setsid gtk-launch cursor\"" },
                { name: "Zed", icon: "", command: "xdg-terminal-exec omarchy-install-zed" },
                { name: "Sublime Text", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add sublime-text-4 && setsid gtk-launch sublime_text\"" },
                { name: "Helix", icon: "", command: "xdg-terminal-exec omarchy-install-helix" },
                { name: "Vim", icon: "", command: "xdg-terminal-exec omarchy-pkg-add vim" },
                { name: "Emacs", icon: "", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add emacs-wayland && systemctl --user enable --now emacs.service\"" }
            ]},
            { name: "Terminal", icon: "", sub: [
                { name: "Alacritty", icon: "", command: "xdg-terminal-exec omarchy-install-terminal alacritty" },
                { name: "Foot", icon: "", command: "xdg-terminal-exec omarchy-install-terminal foot" },
                { name: "Ghostty", icon: "", command: "xdg-terminal-exec omarchy-install-terminal ghostty" },
                { name: "Kitty", icon: "", command: "xdg-terminal-exec omarchy-install-terminal kitty" }
            ]},
            { name: "Browser", icon: "", sub: [
                { name: "Chrome", icon: "", command: "xdg-terminal-exec omarchy-install-browser chrome" },
                { name: "Edge", icon: "", command: "xdg-terminal-exec omarchy-install-browser edge" },
                { name: "Brave", icon: "", command: "xdg-terminal-exec omarchy-install-browser brave" },
                { name: "Brave Origin", icon: "", command: "xdg-terminal-exec omarchy-install-browser brave-origin" },
                { name: "Firefox", icon: "", command: "xdg-terminal-exec omarchy-install-browser firefox" },
                { name: "Zen", icon: "󰖟", command: "xdg-terminal-exec omarchy-install-browser zen" }
            ]},
            { name: "AI", icon: "󱚤", sub: [
                { name: "Dictation", icon: "", command: "xdg-terminal-exec omarchy-voxtype-install" },
                { name: "LM Studio", icon: "󱚤", command: "xdg-terminal-exec omarchy-pkg-add lmstudio-bin" },
                { name: "Ollama", icon: "󱚤", command: "xdg-terminal-exec omarchy-pkg-add ollama" },
                { name: "Crush", icon: "󱚤", command: "xdg-terminal-exec omarchy-pkg-add crush-bin" }
            ]},
            { name: "Gaming", icon: "", sub: [
                { name: "Steam", icon: "", command: "xdg-terminal-exec omarchy-install-gaming-steam" },
                { name: "RetroArch", icon: "", command: "xdg-terminal-exec omarchy-install-gaming-retroarch" },
                { name: "Minecraft", icon: "󰍳", command: "xdg-terminal-exec bash -c \"omarchy-pkg-add minecraft-launcher && setsid gtk-launch minecraft-launcher\"" },
                { name: "GeForce NOW", icon: "󰢹", command: "xdg-terminal-exec omarchy-install-gaming-geforce-now" },
                { name: "Xbox Cloud", icon: "", command: "xdg-terminal-exec omarchy-install-gaming-xbox-cloud" },
                { name: "Xbox Controller", icon: "󰂯", command: "xdg-terminal-exec omarchy-install-gaming-xbox-controllers" },
                { name: "Moonlight", icon: "󰍹", command: "xdg-terminal-exec omarchy-install-gaming-moonlight" },
                { name: "Lutris", icon: "", command: "xdg-terminal-exec omarchy-install-gaming-lutris" },
                { name: "Heroic", icon: "󱓟", command: "xdg-terminal-exec omarchy-install-gaming-heroic" }
            ]},
            { name: "Windows VM", icon: "󰍲", command: "xdg-terminal-exec omarchy-windows-vm install" }
        ]},
        { name: "Remove", icon: "󰭌", sub: [
            { name: "Package", icon: "󰣇", command: "xdg-terminal-exec omarchy-pkg-remove" },
            { name: "Web App", icon: "", command: "xdg-terminal-exec omarchy-webapp-remove" },
            { name: "TUI", icon: "", command: "xdg-terminal-exec omarchy-tui-remove" },
            { name: "Development", icon: "󰵮", sub: [
                { name: "Ruby on Rails", icon: "󰫏", command: "xdg-terminal-exec omarchy-remove-dev-env ruby" },
                { name: "JavaScript", icon: "", sub: [
                    { name: "Node.js", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env node" },
                    { name: "Bun", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env bun" },
                    { name: "Deno", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env deno" }
                ]},
                { name: "Go", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env go" },
                { name: "PHP", icon: "", sub: [
                    { name: "PHP", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env php" },
                    { name: "Laravel", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env laravel" },
                    { name: "Symfony", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env symfony" }
                ]},
                { name: "Python", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env python" },
                { name: "Elixir", icon: "", sub: [
                    { name: "Elixir", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env elixir" },
                    { name: "Phoenix", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env phoenix" }
                ]},
                { name: "Zig", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env zig" },
                { name: "Rust", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env rust" },
                { name: "Java", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env java" },
                { name: ".NET", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env dotnet" },
                { name: "OCaml", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env ocaml" },
                { name: "Clojure", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env clojure" },
                { name: "Scala", icon: "", command: "xdg-terminal-exec omarchy-remove-dev-env scala" }
            ]},
            { name: "Theme", icon: "󰸌", command: "xdg-terminal-exec omarchy-theme-remove" },
            { name: "Browser", icon: "", sub: [
                { name: "Chrome", icon: "", command: "xdg-terminal-exec omarchy-remove-browser chrome" },
                { name: "Edge", icon: "", command: "xdg-terminal-exec omarchy-remove-browser edge" },
                { name: "Brave", icon: "", command: "xdg-terminal-exec omarchy-remove-browser brave" },
                { name: "Brave Origin", icon: "", command: "xdg-terminal-exec omarchy-remove-browser brave-origin" },
                { name: "Firefox", icon: "", command: "xdg-terminal-exec omarchy-remove-browser firefox" },
                { name: "Zen", icon: "", command: "xdg-terminal-exec omarchy-remove-browser zen" }
            ]},
            { name: "Dictation", icon: "", command: "xdg-terminal-exec omarchy-voxtype-remove" },
            { name: "Gaming", icon: "", sub: [
                { name: "Steam", icon: "", command: "xdg-terminal-exec omarchy-remove-gaming-steam" },
                { name: "RetroArch", icon: "", command: "xdg-terminal-exec omarchy-remove-gaming-retroarch" },
                { name: "Minecraft", icon: "󰍳", command: "xdg-terminal-exec omarchy-remove-gaming-minecraft" },
                { name: "GeForce NOW", icon: "󰢹", command: "xdg-terminal-exec omarchy-remove-gaming-geforce-now" },
                { name: "Xbox Cloud", icon: "", command: "xdg-terminal-exec omarchy-remove-gaming-xbox-cloud" },
                { name: "Xbox Controller", icon: "󰖺", command: "xdg-terminal-exec omarchy-remove-gaming-xbox-controllers" },
                { name: "Moonlight", icon: "󰍹", command: "xdg-terminal-exec omarchy-remove-gaming-moonlight" },
                { name: "Lutris", icon: "", command: "xdg-terminal-exec omarchy-remove-gaming-lutris" },
                { name: "Heroic", icon: "󱓟", command: "xdg-terminal-exec omarchy-remove-gaming-heroic" }
            ]},
            { name: "Windows VM", icon: "󰍲", command: "xdg-terminal-exec omarchy-windows-vm remove" },
            { name: "Preinstalls", icon: "󰏓", command: "xdg-terminal-exec omarchy-remove-preinstalls" },
            { name: "Security", icon: "", sub: [
                { name: "Fingerprint", icon: "󰈷", command: "xdg-terminal-exec omarchy-remove-security-fingerprint" },
                { name: "Fido2", icon: "", command: "xdg-terminal-exec omarchy-remove-security-fido2" }
            ]}
        ]},
        { name: "Update", icon: "", sub: [
            { name: "Omarchy", icon: "", command: "xdg-terminal-exec omarchy-update" },
            { name: "Channel", icon: "󰔫", sub: [
                { name: "Stable", icon: "🟢", command: "xdg-terminal-exec omarchy-channel-set stable" },
                { name: "RC", icon: "🟡", command: "xdg-terminal-exec omarchy-channel-set rc" },
                { name: "Edge", icon: "🟠", command: "xdg-terminal-exec omarchy-channel-set edge" },
                { name: "Dev", icon: "🔴", command: "xdg-terminal-exec omarchy-channel-set dev" }
            ]},
            { name: "Config (Default)", icon: "", sub: [
                { name: "Hyprland", icon: "", command: "xdg-terminal-exec omarchy-refresh-hyprland" },
                { name: "Hypridle", icon: "", command: "xdg-terminal-exec omarchy-refresh-hypridle" },
                { name: "Hyprlock", icon: "", command: "xdg-terminal-exec omarchy-refresh-hyprlock" },
                { name: "Hyprsunset", icon: "", command: "xdg-terminal-exec omarchy-refresh-hyprsunset" },
                { name: "Plymouth", icon: "󱣴", command: "xdg-terminal-exec omarchy-refresh-plymouth" },
                { name: "Swayosd", icon: "", command: "xdg-terminal-exec omarchy-refresh-swayosd" },
                { name: "Tmux", icon: "", command: "xdg-terminal-exec omarchy-refresh-tmux" },
                { name: "Walker", icon: "󰌧", command: "xdg-terminal-exec omarchy-refresh-walker" },
                { name: "Waybar", icon: "󰍜", command: "xdg-terminal-exec omarchy-refresh-waybar" }
            ]},
            { name: "Extra Themes", icon: "󰸌", command: "xdg-terminal-exec omarchy-theme-update" },
            { name: "Process (Restart)", icon: "", sub: [
                { name: "Hypridle", icon: "", command: "omarchy-restart-hypridle" },
                { name: "Hyprsunset", icon: "", command: "omarchy-restart-hyprsunset" },
                { name: "Mako", icon: "󰎟", command: "omarchy-restart-mako" },
                { name: "Swayosd", icon: "", command: "omarchy-restart-swayosd" },
                { name: "Walker", icon: "󰌧", command: "omarchy-restart-walker" },
                { name: "Waybar", icon: "󰍜", command: "omarchy-restart-waybar" }
            ]},
            { name: "Hardware (Restart)", icon: "󰇅", sub: [
                { name: "Audio", icon: "", command: "xdg-terminal-exec omarchy-restart-pipewire" },
                { name: "Wi-Fi", icon: "󱚾", command: "xdg-terminal-exec omarchy-restart-wifi" },
                { name: "Bluetooth", icon: "󰂯", command: "xdg-terminal-exec omarchy-restart-bluetooth" },
                { name: "Trackpad", icon: "󰟸", command: "xdg-terminal-exec omarchy-restart-trackpad" }
            ]},
            { name: "Firmware", icon: "", command: "xdg-terminal-exec omarchy-update-firmware" },
            { name: "Password", icon: "", sub: [
                { name: "Drive Encryption", icon: "", command: "xdg-terminal-exec omarchy-drive-password" },
                { name: "User", icon: "", command: "xdg-terminal-exec passwd" }
            ]},
            { name: "Timezone", icon: "", command: "xdg-terminal-exec omarchy-tz-select" },
            { name: "Time", icon: "", command: "xdg-terminal-exec omarchy-update-time" }
        ]},
        { name: "About", icon: "", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call about toggle" },
        { name: "System", icon: "", command: "quickshell ipc --path ~/.config/quickshell/shell.qml call power toggle" }
    ]
}
