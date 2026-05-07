# Manual Steps Required:

# - Add raycast script for launching emacs via terminal login-shell
#   currently in Dropbox/raycast_scripts/emacs

{
  description = "My system configuration";
  # Command to reload:

  # darwin-rebuild switch --flake ~/.config/nix

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          nixpkgs.config.allowUnfree = true;

          # Use touch ID when running darwin-rebuild command above:
          security.pam.services.sudo_local.touchIdAuth = true;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility. please read the changelog
          # before changing: `darwin-rebuild changelog`.
          system.stateVersion = 4;

          # The platform the configuration will be used on.
          # If you're on an Intel system, replace with "x86_64-darwin"
          nixpkgs.hostPlatform = "aarch64-darwin";

          # Declare the user that will be running `nix-darwin`.
          users.users.christopherchambers = {
            name = "christopherchambers";
            home = "/Users/christopherchambers";
          };
          system.primaryUser = "christopherchambers";

          ids.gids.nixbld = 350;

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true;

          environment.systemPackages = with pkgs; [
            as-tree # show file/dir listing as tree

            csvlens # csv viewing utility
            tidy-viewer # csv viewing utility

            fastfetch # neofetch replacement

            automake # pdf-tools
            cmake # vterm
            emacsPackages.cask # required for building pdf-tools
            emacsPackages.jinx # spell-checking
            enchant # spell-checking
            hunspell # spell-checking
            hunspellDicts.en_GB-large # spell-checking
            poppler # pdf-tools
            # libpng # required for building pdf-tools
            watchexec

            btop
            dust
            dua
            xh # curl / http like CLI
            fzf
            fzf-git-sh
            yazi

            groff

            ripgrep-all

            uv
            ruff
            basedpyright

            # nil                     # nix language server
            nixd # nix language server

            vips
            # postgresql
            # syncthing
            # sdcv # stardict dictionary viewer, for Webster's 1913

            tmux
            tmuxp # tmux session manager

            exiftool

            # -----
            chezmoi
            starship
            # direnv
            bat
            cheat
            cloc
            coreutils
            # editorconfig
            fd
            git
            delta
            jq
            lsd
            gnumake
            neovim
            rename
            ripgrep
            shellcheck
            wget
            yamllint
            zoxide
            zsh

            tree
            tealdeer
            keycastr
            ffmpeg # mov -> gif

            raycast # unfree
            # alt-tab-macos
            firefox-devedition
            _1password-cli
            carapace
            # karabiner-elements
            expect

            # ------------------------------------------------------------
            # Note: Homebrew and npm -g / npm installation instead:
            # https://stackoverflow.com/questions/78862090/could-not-find-chromium-rev-1108766-this-can-occur-if-either
            # ------------------------------------------------------------
            # mermaid-cli   # attempt install via npm

            # python313Packages.shtab
            insomnia

            # fde monorepo:
            # docker
            # aws-sam-cli
            # awscli
            terraform

            zoom-us
          ];

          # Creates symlink at /run/current-system/etc/fzf-git:
          environment.etc."fzf-git" = {
            source = "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh";
          };

          environment.systemPath = [
            "/Users/christopherchambers/bin"
            "/opt/homebrew/bin"
            "/opt/homebrew/sbin"
            "/Library/TeX/texbin"
          ];

          homebrew = {
            enable = true;
            # onActivation.cleanup = "uninstall";
            taps = [
              "nextjournal/brew"
              # "FelixKratz/formulae"
            ];
            brews = [
              "bash-language-server" # not tested this with nix here
              # "mermaid-cli"
              {
                name = "d12frosted/emacs-plus/emacs-plus@30";
                args = [
                  "with-imagemagick"
                  "with-xwidgets"
                ];
              }
            ];
            casks = [
              "disk-inventory-x"
              "ghostty"
              "alt-tab"
              "font-sauce-code-pro-nerd-font" # not tested this with nix here
              "amethyst"
              "karabiner-elements"
              "beekeeper-studio"
              "postico"
              # "mactex"
              # "libreoffice"
              "docker-desktop"
            ];
          };
          # https://github.com/LnL7/nix-darwin/issues/1041
          # services.karabiner-elements.enable = true;
        };
      homeconfig =
        { pkgs, ... }:
        {
          # this is internal compatibility configuration
          # for home-manager, don't change this!
          home.stateVersion = "24.05";

          # Let home-manager install and manage itself:
          programs.home-manager.enable = true;
          home.packages = with pkgs; [
            nixfmt-rfc-style
            nix-direnv
          ];

          # NOTE: Won't work unless home-manager manages dotfiles.
          home.sessionVariables = {
            EDITOR = "emacsclient -c -a 'emacs'";
          };

          programs.zsh.shellAliases = {
            http = "xh";
            https = "xhs";
          };

        };
    in
    {
      darwinConfigurations."scylla" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.users.christopherchambers = homeconfig;
          }
        ];
      };
    };
}
