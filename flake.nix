{
  description = "Claude Desktop for Linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Optional: more up-to-date claude-code from dedicated flake
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    claude-code-nix,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Use claude-code from input if it has packages, otherwise from nixpkgs
      claude-code-pkg =
        if claude-code-nix ? packages.${system}
        then claude-code-nix.packages.${system}.default or claude-code-nix.packages.${system}.claude-code
        else pkgs.claude-code;

      # Helper function to build FHS env
      mkClaudeDesktopFHS = basePackage:
        pkgs.buildFHSEnv {
          name = "claude-desktop";
          targetPkgs = pkgs:
            with pkgs; [
              docker
              glibc
              openssl
              nodejs
              uv
            ];
          runScript = "${basePackage}/bin/claude-desktop";
          extraInstallCommands = ''
            # Copy desktop file from the base package
            mkdir -p $out/share/applications
            cp ${basePackage}/share/applications/claude.desktop $out/share/applications/

            # Copy icons
            mkdir -p $out/share/icons
            cp -r ${basePackage}/share/icons/* $out/share/icons/
          '';
        };
    in {
      packages = rec {
        patchy-cnb = pkgs.callPackage ./pkgs/patchy-cnb.nix {};
        claude-desktop = pkgs.callPackage ./pkgs/claude-desktop.nix {
          inherit patchy-cnb;
        };
        claude-desktop-with-claude-code = pkgs.callPackage ./pkgs/claude-desktop.nix {
          inherit patchy-cnb;
          claude-code = claude-code-pkg; # Uses claude-code from input or nixpkgs
        };
        claude-desktop-with-fhs = mkClaudeDesktopFHS claude-desktop;
        claude-desktop-with-fhs-with-claude-code = mkClaudeDesktopFHS claude-desktop-with-claude-code;
        default = claude-desktop;
      };
    });
}
