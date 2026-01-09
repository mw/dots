{
  description = "basepkgs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    neovim-src = {
      url = "github:neovim/neovim?ref=master";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, neovim-src }:
  let
    neovimOverlay = final: prev: {
      neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (old: {
        src = neovim-src;

        # post-build version check fails
        doInstallCheck = false;
      });
    };
  in {
    packages = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ neovimOverlay ];
          };

          isDarwin = pkgs.stdenv.isDarwin;
          localePkgs =
            if isDarwin then
              [ pkgs.darwin.locale ]
            else
              [ pkgs.glibcLocales pkgs.locale ];
        in
        {
          basepkgs = pkgs.buildEnv {
            name = "basepkgs";
            paths = with pkgs; [
              b3sum
              bash
              bat
              bottom
              coreutils-prefixed
              diffutils
              direnv
              fd
              fzf
              gawk
              git
              git-lfs
              gnutar
              go
              jq
              lsd
              ncurses5
              neovim
              nix-direnv
              nmap
              rclone
              restic
              ripgrep
              rustup
              sqlite-interactive
              starship
              tailscale
              tmux
              tree-sitter
              unzip
              uv
              zoxide
              zsh
              zsh-autosuggestions
              zsh-syntax-highlighting
              zstd
            ] ++ localePkgs;
            extraOutputsToInstall = [ "man" "doc" ];
          };
        }
      );
  };
}
