{
  description = "basepkgs";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
  };

  outputs = { self, nixpkgs }: {
    packages = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
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
              delta
              diffutils
              direnv
              fd
              fzf
              gawk
              git
              git-lfs
              gnutar
              go
              jjui
              jq
              jujutsu
              lsd
              ncurses5
              neovim
              neovim-remote
              nix-direnv
              nmap
              pnpm
              rclone
              restic
              ripgrep
              rustup
              sqlite-interactive
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
