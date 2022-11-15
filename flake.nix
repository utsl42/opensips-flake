{
  description = "OpenSIPS - flexible and robust SIP (RFC3261) server";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      overlay = self: super: { };
      pkgsForSystem = system: (import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
        ];
      });
    in
    {
      overlays.default = final: prev: {
        opensips = final.callPackage ./opensips/default.nix { };
      };
      packages = forAllSystems
        (system:
          let
            pkgs = pkgsForSystem system;
          in
          {
            opensips = pkgs.opensips;
            default = pkgs.opensips;
          });
    };
}
