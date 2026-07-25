# Sandbox image for microsandbox: always Linux, at the host CPU arch so the
# guest VM runs natively. The image is assembled with host-platform tools, so
# no Linux builder is needed on macOS: the Linux packages in `contents` are
# substituted from the binary cache rather than built. Shim files (/bin/sh,
# /usr/bin/env, /etc/passwd, certs) are created in extraCommands for the same
# reason -- dockerTools' runCommand-based helpers would need a Linux builder.
{ system ? builtins.currentSystem
, linuxSystem ? builtins.replaceStrings [ "darwin" ] [ "linux" ] system
, pkgs ? import <nixpkgs> { inherit system; }
, linuxPkgs ? if linuxSystem == system then pkgs else import <nixpkgs> { system = linuxSystem; }
}:

pkgs.dockerTools.buildLayeredImage {
  name = "pi-sandbox";
  tag = "latest";
  contents = with linuxPkgs; [
    bash
    cacert
    coreutils
    curl
    diffutils
    fd
    gnugrep
    gnused
    jq
    jujutsu
    nix
    python3
    ripgrep
    uv
  ];
  extraCommands = ''
    mkdir -p bin usr/bin etc/nix etc/ssl/certs
    ln -sf ${linuxPkgs.bash}/bin/bash bin/sh
    ln -sf ${linuxPkgs.coreutils}/bin/env usr/bin/env
    ln -sf ${linuxPkgs.cacert}/etc/ssl/certs/ca-bundle.crt etc/ssl/certs/ca-bundle.crt
    echo "experimental-features = nix-command flakes" > etc/nix/nix.conf
    echo "build-users-group =" >> etc/nix/nix.conf
    echo "root:x:0:0:root:/root:/bin/bash" > etc/passwd
    echo "root:x:0:" > etc/group
  '';
  config = {
    Cmd = [ "/bin/bash" ];
    Env = [
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}

