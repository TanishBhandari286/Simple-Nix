{
  description = "Zenful nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile
      environment.systemPackages = [
        pkgs.neovim
        pkgs.tmux
        pkgs.alacritty
        pkgs.yt-dlp
        pkgs.jq
        pkgs.mkalias
        pkgs.home-manager
	pkgs.zoxide
	pkgs.fzf
	pkgs.nushell
	pkgs.eza
	pkgs.starship
	pkgs.bat
	pkgs.ripgrep
	pkgs.thefuck
	pkgs.lazygit
	pkgs.tmux
	pkgs.fastfetch
	pkgs.onefetch
	pkgs.onefetch
	pkgs.yazi
	pkgs.ranger
	pkgs.gcc
	pkgs.go
        pkgs.fd
        pkgs.carapace
        pkgs.nodejs_23
      ];

      # Homebrew packages
      homebrew = {
        enable = true;
        brews = [
          "mas"
	  "zsh-autosuggestions"
	  "zsh-syntax-highlighting"
          "ffmpeg"
          "pipx"
	  "make"
	  "cmake"
        ];
        casks = [
          "hammerspoon"
          "karabiner-elements"
          "iina"
          "the-unarchiver"
          "obs"
          "brave-browser"
          "firefox"
          "nikitabobko/tap/aerospace"
          "obsidian"
          "font-jetbrains-mono-nerd-font"
          "google-drive"
          "wezterm"
          "telegram"
          "visual-studio-code"
          "intellij-idea"
          "whatsapp"
          "discord"
          "slack"
          "google-drive"
          "microsoft-office"
          "stremio"
          "aldente"
          "cakebrew"
          "balenaetcher"
          "chatgpt"
          "font-hack-nerd-font"
          "iina"
          "jdownloader"
          "raycast"
          "alfred"
          "spacedrive"
          "tailscale"
          "zed"
        ];
        masApps = {
          "Bitwarden" = 1352778147;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      # Activation script for setting up applications in /Applications
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

      # System preferences
      system.defaults = {
        dock.autohide = true;
        dock.persistent-apps = [
        "/Applications/WezTerm.app"
          "/Applications/Firefox.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/System Settings.app"
          "/Applications/Stremio.app"
          "/Applications/Discord.app"
          "/Applications/Obsidian.app"
          "/Applications/IntelliJ IDEA.app"
          "/Applications/WhatsApp.app"
          "/Applications/Telegram.app"
        ];
        finder.FXPreferredViewStyle = "clmv";
        loginwindow.GuestEnabled = false;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.AppleInterfaceStyle = "Dark";
        NSGlobalDomain.KeyRepeat = 2;
      };

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment
      programs.zsh.enable = true;

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing
      system.stateVersion = 5;

      security.pam.enableSudoTouchIdAuth = true;

      # The platform the configuration will be used on
      nixpkgs.hostPlatform = "aarch64-darwin"; # Change to "x86_64-darwin" if you are on Intel Mac
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#mini
    darwinConfigurations."mini" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "air";
            autoMigrate = true;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience
    darwinPackages = self.darwinConfigurations."mini".pkgs;
  };
}

