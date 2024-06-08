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
          isDarwin = builtins.match ".*linux" system == null;
          localePkgs =
            if isDarwin then
              [ pkgs.darwin.locale ]
            else
              [ pkgs.glibcLocales pkgs.locale ];
          pypkgs = pkgs.python3.withPackages (pp: with pp; [
            httpx
            pandas
            pip
            python-lsp-server
          ]);
        in
        {
          basepkgs = pkgs.buildEnv {
            name = "basepkgs";
            paths = with pkgs; [
              b3sum
              bash
              bat
              coreutils-prefixed
              ctags
              diffutils
              direnv
              fd
              fzf
              gawk
              git
              git-lfs
              gnutar
              go
              golangci-lint
              gopls
              gotools
              htop
              jq
              lsd
              luajitPackages.lua-lsp
              mold
              mosh
              ncurses5
              neovim
              nmap
              nodePackages.vscode-langservers-extracted
              pypkgs
              rclone
              restic
              ripgrep
              rustup
              sqlite-interactive
              starship
              tailscale
              tmux
              tree
              tree-sitter
              unzip
              uv
              zoxide
              zsh
              zstd
            ] ++ localePkgs;
            extraOutputsToInstall = [ "man" "doc" ];
          };
        }
      );
  };
}
