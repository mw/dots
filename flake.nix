{
  description = "basepkgs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    packages = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
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
