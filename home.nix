{ config, pkgs, ... }:

{
  imports = [
    ./wallpapers.nix
  ];

  # Home Manager details
  home.username = "ken";
  home.homeDirectory = "/home/ken";
  targets.genericLinux.enable = true;

  home.stateVersion = "26.05";

  # Nix packages environment
  home.packages = with pkgs; [
    matugen
    quickshell
    tree-sitter
    awww
    vicinae
  ];

  # Starship prompt setup
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Zsh declarative setup
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Custom aliases
    shellAliases = {
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      ":q" = "exit";
      ":wq" = "exit";
      hm = "home-manager";
      hme = "nvim $HOME/.config/home-manager/home.nix";
    };

    initContent = ''
      # Include Flatpak paths so Vicinae indexes desktop applications
      export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share:$HOME/.local/share:${"${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"}"
      
      export PATH="$HOME/.local/bin:$HOME/.local/share/SLSsteam/path:$HOME/.nix-profile/bin:$PATH"
      export PAGER="nvim -c 'set ft=man' -"
      alias vac="source .venv/bin/activate"

      hms() {
        local dir="$HOME/.config/home-manager"
        git -C "$dir" add . || return
        git -C "$dir" diff --cached --quiet \
          || git -C "$dir" commit -m "home-manager switch: $(date +'%F %T')" || return
        git -C "$dir" push || return
        home-manager switch
      }
    '';
  };

  # Dotfile symlinks
  home.file.".config/nvim" = {
    source = ./dots/nvim;
    recursive = true;
  };
  home.file.".config/niri" = {
    source = ./dots/niri;
    recursive = true;
  };
  home.file.".config/matugen" = {
    source = ./dots/matugen;
    recursive = true;
  };

  # Home Manager self-management
  programs.home-manager.enable = true;
}
