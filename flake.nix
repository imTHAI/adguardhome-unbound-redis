{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
  let
    systems = [ "aarch64-darwin" "x86_64-linux" ];
    forAll  = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    image    = "imthai/adguardhome-unbound-redis";
    workflow = "docker.yml";
    mkApp = pkgs: script: {
      type    = "app";
      program = toString (pkgs.writeShellScript "app" script);
    };
  in {
    devShells = forAll (pkgs: {
      default = pkgs.mkShell { packages = [ pkgs.docker pkgs.gh ]; };
    });
    apps = forAll (pkgs: {
      test = mkApp pkgs ''
        set -e
        docker build --platform linux/arm64 -t ${image}:test .
        docker push ${image}:test
        echo "✓ ${image}:test pushed"
      '';
      ci = mkApp pkgs ''
        set -e
        git push
        gh workflow run ${workflow}
        echo "✓ Workflow déclenché"
      '';
    });
  };
}
