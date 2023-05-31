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
            pytorch
          ]);
        in
        {
          basepkgs = pkgs.buildEnv {
            name = "basepkgs";
            paths = with pkgs; [
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
              go
              golangci-lint
              gopls
              gotools
              gnutar
              htop
              jq
              lsd
              luajitPackages.lua-lsp
              mosh
              ncurses5
              neovim
              nodePackages.vscode-langservers-extracted
              pypkgs
              restic
              ripgrep
              rnix-lsp
              rustup
              sqlite-interactive
              starship
              tailscale
              tmux
              tree
              unzip
              wordnet
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
