{
  description = "basepkgs";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0.1";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in
    {
      packages = nixpkgs.lib.genAttrs systems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          localePkgs =
            if pkgs.stdenv.isDarwin then
              [ pkgs.darwin.locale ]
            else
              [ pkgs.glibcLocales pkgs.locale ];
        in
        {
          # msb extracted from the same wheel uv installs for extensions.py, so
          # the CLI and the Python module are kept in sync. Updating the lock
          # file updates both.
          microsandbox =
            let
              lock = fromTOML (
                builtins.readFile ./pi/agent/extensions/extensions.py.lock
              );
              package = builtins.head (
                builtins.filter (p: p.name == "microsandbox") lock.package
              );
              platform = {
                x86_64-linux = [ "linux" "x86_64" ];
                aarch64-linux = [ "linux" "aarch64" ];
                aarch64-darwin = [ "macosx" "arm64" ];
              }.${system} or (throw "microsandbox: unsupported system ${system}");
              wheel = builtins.head (
                builtins.filter (
                  w: builtins.all (s: pkgs.lib.hasInfix s w.url) platform
                ) package.wheels
              );
              entitlements = pkgs.writeText "msb-entitlements.plist" ''
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
                  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                  <key>com.apple.security.hypervisor</key>
                  <true/>
                </dict>
                </plist>
              '';
            in
            pkgs.stdenv.mkDerivation {
              pname = package.name;
              inherit (package) version;
              src = pkgs.fetchurl { inherit (wheel) url hash; };

              nativeBuildInputs = [ pkgs.unzip ];

              unpackPhase = "unzip $src";

              installPhase = ''
                install -Dm755 microsandbox/_bundled/bin/msb $out/bin/msb
                install -Dm755 microsandbox/_bundled/lib/* -t $out/lib
              '' + pkgs.lib.optionalString pkgs.stdenv.isLinux ''
                patchelf \
                  --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
                  --set-rpath ${pkgs.libcap_ng}/lib \
                  $out/bin/msb
              '';

              postFixup = pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
                /usr/bin/codesign --force --sign - \
                  --entitlements ${entitlements} \
                  $out/bin/msb
              '';
            };

          basepkgs = pkgs.buildEnv {
            name = "basepkgs";
            paths = with pkgs; [
              age
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
              openssh
              pnpm
              rclone
              restic
              ripgrep
              rsync
              rustup
              sqlite-interactive
              tailscale
              tmux
              tree-sitter
              unzip
              uv
              zoxide
              zsh
              self.packages.${system}.microsandbox
              zsh-autosuggestions
              zsh-syntax-highlighting
              zstd
            ] ++ localePkgs;
            extraOutputsToInstall = [ "man" "doc" ];
          };
        });
    };
}
