{
  description = "ai.nvim development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        cqfd = pkgs.stdenv.mkDerivation rec {
          pname = "cqfd";
          version = "5.9.0";

          src = pkgs.fetchFromGitHub {
            owner = "savoirfairelinux";
            repo = "cqfd";
            rev = "v${version}";
            hash = "sha256-2u6ymbq9AJJROnlvANTwAd54kwdaEn7ueaTw4iSOhYw=";
          };

          nativeBuildInputs = [ pkgs.makeWrapper ];

          buildInputs = [ pkgs.bash pkgs.docker ];

          dontBuild = true;

          installPhase = ''
            make install PREFIX=$out
          '';

          postFixup = ''
            wrapProgram $out/bin/cqfd \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.docker pkgs.bash ]}
          '';

          meta = {
            description = "Run commands inside a per-project Docker container";
            homepage = "https://github.com/savoirfairelinux/cqfd";
            license = pkgs.lib.licenses.gpl3;
            platforms = pkgs.lib.platforms.linux;
          };
        };

      in {
        packages = {
          inherit cqfd;
          default = cqfd;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            cqfd
            pkgs.docker
            pkgs.git
            pkgs.gnumake
          ];

          shellHook = ''
            echo "ai.nvim dev shell ready"
            echo "Run 'make' to build and test via cqfd+docker"
          '';
        };
      });
}
