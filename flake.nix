{
  description = "Claude Desktop for Linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      packages = rec {
        patchy-cnb = pkgs.callPackage ./pkgs/patchy-cnb.nix {};
        claude-desktop = pkgs.callPackage ./pkgs/claude-desktop.nix {
          inherit patchy-cnb;
        };
        claude-desktop-with-claude-code = pkgs.callPackage ./pkgs/claude-desktop.nix {
          inherit patchy-cnb;
          claude-code = pkgs.claude-code; # Uses claude-code from pkgs (respects overlays)
        };
        claude-desktop-with-fhs = pkgs.buildFHSEnv {
          name = "claude-desktop";
          targetPkgs = pkgs:
            with pkgs; [
              docker
              glibc
              openssl
              nodejs
              uv
            ];
          runScript = "${claude-desktop}/bin/claude-desktop";
          extraInstallCommands = ''
            # Copy desktop file from the claude-desktop package
            mkdir -p $out/share/applications
            cp ${claude-desktop}/share/applications/claude.desktop $out/share/applications/

            # Copy icons
            mkdir -p $out/share/icons
            cp -r ${claude-desktop}/share/icons/* $out/share/icons/
          '';
        };
        claude-desktop-with-fhs-with-claude-code = pkgs.buildFHSEnv {
          name = "claude-desktop";
          targetPkgs = pkgs:
            with pkgs; [
              docker
              glibc
              openssl
              nodejs
              uv
            ];
          runScript = "${claude-desktop-with-claude-code}/bin/claude-desktop";
          extraInstallCommands = ''
            # Copy desktop file from the claude-desktop-with-claude-code package
            mkdir -p $out/share/applications
            cp ${claude-desktop-with-claude-code}/share/applications/claude.desktop $out/share/applications/

            # Copy icons
            mkdir -p $out/share/icons
            cp -r ${claude-desktop-with-claude-code}/share/icons/* $out/share/icons/
          '';
        };
        default = claude-desktop;
      };
    });
}
