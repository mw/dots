{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; } }:

pkgs.dockerTools.buildLayeredImage {
  name = "pi-sandbox";
  tag = "latest";
  contents = with pkgs; [
    bash
    coreutils
    curl
    diffutils
    dockerTools.binSh
    dockerTools.caCertificates
    dockerTools.fakeNss
    dockerTools.usrBinEnv
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
    mkdir -p etc/nix
    echo "experimental-features = nix-command flakes" > etc/nix/nix.conf
    echo "build-users-group =" >> etc/nix/nix.conf
  '';
  config = {
    Cmd = [ "/bin/bash" ];
    Env = [
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
