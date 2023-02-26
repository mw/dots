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
          locale = if isDarwin then pkgs.darwin.locale else pkgs.locale;
          localePkgs =
            if isDarwin then
              [ pkgs.darwin.locale ]
            else
              [ pkgs.glibcLocales pkgs.locale ];
          pypkgs = pkgs.python3.withPackages (pp: with pp; [
            pandas
            requests
          ]);
        in
        {
          basepkgs = pkgs.buildEnv {
            name = "basepkgs";
            paths = with pkgs; [
              bash
              bat
              clang
              coreutils-prefixed
              ctags
              diffutils
              fd
              fzf
              gawk
              git
              gnutar
              htop
              jq
              lsd
              luajitPackages.lua-lsp
              mosh
              neovim
              nodePackages.vscode-langservers-extracted
              restic
              ripgrep
              rnix-lsp
              sqlite
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
          py = pkgs.buildEnv {
            name = "py";
            paths = with pkgs; [
              pypkgs
            ];
            extraOutputsToInstall = [ "man" "doc" ];
          };
          rs = pkgs.buildEnv {
            name = "rs";
            paths = with pkgs; [
              cargo
              clippy
              rust-analyzer
              rustc
              rustfmt
            ];
            extraOutputsToInstall = [ "man" "doc" ];
          };
          go = pkgs.buildEnv {
            name = "go";
            paths = with pkgs; [
              go
              golangci-lint
              gopls
              gotools
            ];
            extraOutputsToInstall = [ "man" "doc" ];
          };
        }
      );
  };
}
