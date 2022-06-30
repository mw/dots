{
  description = "basepkgs";

  inputs = {
    nixpkgs.url = "nixpkgs/22.05";
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
        in
        {
          basepkgs = pkgs.buildEnv {
            name = "basepkgs";
            paths = with pkgs; [
              bash
              bat
              coreutils-prefixed
              diffutils
              fd
              fzf
              gawk
              git
              gnutar
              htop
              jq
              mosh
              neovim
              restic
              ripgrep
              starship
              tmux
              unzip
              wordnet
              zoxide
              zsh
            ] ++ localePkgs;
            extraOutputsToInstall = [ "man" "doc" ];
          };
          dev = pkgs.buildEnv {
            name = "dev";
            paths = with pkgs; [
              cargo
              clang
              clippy
              go
              gopls
              gotools
              go-tools
              nodejs
              nodePackages.vscode-langservers-extracted
              python39
              python39Packages.black
              python39Packages.python-lsp-black
              python39Packages.python-lsp-server
              python39Packages.requests
              rnix-lsp
              rust-analyzer
              rustc
              rustfmt
              sumneko-lua-language-server
            ];
            extraOutputsToInstall = [ "man" "doc" ];
          };
        }
      );
  };
}
