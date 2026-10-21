{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ken";
  home.homeDirectory = "/home/ken";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    neovim
    quickshell
  ];

  # Bring in Starship
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
        export PATH="$HOME/.local/bin:$HOME/.local/share/SLSsteam/path:$HOME/.nix-profile/bin:$PATH"

        hms() {
          local dir="$HOME/.config/home-manager"   # adjust to your path
          git -C "$dir" add . || return
          git -C "$dir" diff --cached --quiet \
            || git -C "$dir" commit -m "home-manager switch: $(date +'%F %T')" || return
          git -C "$dir" push || return
          home-manager switch
        }
    '';
  };
  

  # dots
  home.file.".config/quickshell" = {
    source = ./dots/quickshell;
    recursive = true;
  };
  home.file.".config/nvim" = {
    source = ./dots/nvim;
  };
  home.file.".config/niri" = {
    source = ./dots/niri;
  };
  home.file.".config/matugen" = {
    source = ./dots/matugen;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
