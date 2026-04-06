{
  description = "Glide Browser - a Firefox-based web browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          glide-browser = pkgs.callPackage ./package.nix { };
          default = self.packages.${system}.glide-browser;
        }
      );

      overlays.default = final: prev: {
        glide-browser = final.callPackage ./package.nix { };
      };
    };
}
