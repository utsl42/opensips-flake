{
  description = "OpenSIPS - flexible and robust SIP (RFC3261) server";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
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
        inherit (final.callPackages ./opensips/default.nix { })
          opensips_34
          opensips_35
          opensips_36
        ;
        opensips-cli = final.callPackage ./opensips-cli/default.nix { };
      };
      tests = forAllSystems (system: {
        unit-test = import ./opensips/configfile_test.nix { pkgs = pkgsForSystem system; };
      });
      packages = forAllSystems
        (system:
          let
            pkgs = pkgsForSystem system;
          in
          {
            opensips_34 = pkgs.opensips_34;
            opensips_35 = pkgs.opensips_35;
            opensips_36 = pkgs.opensips_36;
            opensips-cli = pkgs.opensips-cli;
            opensips = pkgs.opensips_36;
            default = pkgs.opensips_36;
          });
      nixosModules.opensips = {
        imports = [ ./opensips/module.nix ];
        nixpkgs.overlays = [ self.overlays.default ];
      };
      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [
            self.nixosModules.opensips
            ({ pkgs, ... }: {
              boot.isContainer = true;
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
              services.opensips = {
                enable = true;
                globalConfig = ''
                  log_level=2
                  xlog_level=2
                  udp_workers=4
                  socket=udp:*:5060
                '';
                moduleParameters = {
                  proto_udp = { };
                  signaling = { };
                  usrloc = { };
                  tm = {
                    fr_timeout = 5;
                    fr_inv_timeout = 30;
                  };
                  registrar = {
                    attr_avp = "$avp(attr)";
                  };
                };
                routeScript = ''
                  route {
                    exit;
                  }
                '';
              };

            })
          ];
      };
    };
}
