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
              cargo
              clang
              clippy
              diffutils
              fd
              fzf
              gawk
              git
              gnutar
              go
              gopls
              gotools
              go-tools
              htop
              iotop
              jq
              mosh
              neovim
              nodejs
              nodePackages.vscode-langservers-extracted
              python39
              restic
              ripgrep
              rnix-lsp
              rust-analyzer
              rustc
              rustfmt
              sumneko-lua-language-server
              starship
              tmux
              unzip
              zoxide
              zsh
              python39Packages.black
              python39Packages.python-lsp-black
              python39Packages.python-lsp-server
              python39Packages.requests
            ] ++ localePkgs;
            extraOutputsToInstall = [ "man" "doc" ];
          };
        }
      );
  };
}
