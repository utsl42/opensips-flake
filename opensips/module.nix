{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkPackageOption mkIf mkOption optionalString types concatStringsSep concatMapStrings mapAttrsToList;
  cfg = config.services.opensips;
  caps = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
  configfile = import ./configfile.nix { inherit pkgs; };
  # for global config specified in Nix config
  globalsFile = pkgs.writeTextFile {
    name = "opensips-globals.cfg";
    text = cfg.globalConfig;
  };
  # for routes specified in Nix config
  routesFile = pkgs.writeTextFile {
    name = "opensips-routes.cfg";
    text = cfg.routeScript;
  };
  # generate loadmodule and modparam lines
  modulesFile = pkgs.writeTextFile {
    name = "opensips-modules.cfg";
    text = ''
      mpath="${pkgs.opensips}/mod"
    '' + configfile.moduleConfiguration cfg.moduleParameters;
  };
  configFiles = [ globalsFile modulesFile routesFile ] ++ cfg.extraConfigFiles;
in
{
  options = {
    services.opensips = {
      enable = mkEnableOption (lib.mdDoc "OpenSIPS SIP Proxy");
      package = mkPackageOption pkgs "opensips" { };
      globalConfig = mkOption {
        type = types.lines;
        description = ''
          OpenSIPS SIP proxy global configuration parameters.
          <https://www.opensips.org>
        '';
      };
      moduleParameters = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          module parameters in the form of:
            module = {
              key = "value";
            }
          should be turned into:
            loadparam("module.so")
            modparam("module", "key", "value")
        '';
      };
      routeScript = mkOption {
        type = types.str;
        description = ''
          OpenSIPS route script
        '';
        default = "";
      };
      extraConfigFiles = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra configuration files to load
        '';
      };
      sharedMemory = mkOption {
        type = types.int;
        default = 512;
        description = ''
          Size of shared memory allocated in Megabytes
        '';
      };
      pkgMemory = mkOption {
        type = types.int;
        default = 8;
        description = ''
          Size of pkg memory allocated in Megabytes
        '';
      };
    };
  };

  config = mkIf cfg.enable
    {
      environment.systemPackages = [ cfg.package ];

      environment.etc."opensips/opensips-globals.cfg".source = globalsFile;
      environment.etc."opensips/opensips-routes.cfg".source = routesFile;
      environment.etc."opensips/opensips-modules.cfg".source = modulesFile;
      environment.etc."opensips/opensips.cfg".source = pkgs.writeTextFile {
        name = "opensips.cfg";
        text = concatMapStrings
          (p: ''
            include_file "${p}"
          '')
          configFiles;
        checkPhase = ''
          ln -s $out opensips.cfg
          ${cfg.package}/bin/opensips -C -f opensips.cfg
        '';
      };

      users.users.opensips = {
        description = "OpenSIPS daemon user";
        isSystemUser = true;
        group = "opensips";
      };
      users.groups.opensips = {};

      systemd.services.opensips = {
        description = "OpenSIPS SIP proxy";
        wantedBy = [ "multi-user.target" ];
        reloadTriggers = [ routesFile ] ++ cfg.extraConfigFiles;
        restartTriggers = [ globalsFile modulesFile ];
        serviceConfig = {
          Type = "forking";
          Restart = "on-failure";
          User = "opensips";
          Group = "opensips";
          ExecStart = "${cfg.package}/bin/opensips -f /etc/opensips/opensips.cfg -m ${toString cfg.sharedMemory} -M ${toString cfg.pkgMemory}";
          ExecReload = "${pkgs.opensips-cli}/bin/opensips-cli -x mi reload_routes";
          RuntimeDirectory = "opensips";
          CapabilityBoundingSet = caps;
          AmbientCapabilities = caps;
          ProtectSystem = "full";
          ProtectHome = "yes";
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          PrivateTmp = true;
          PrivateDevices = true;
          # TODO: are these correct? useful?
          SystemCallFilter = "~@cpu-emulation @debug @keyring @module @mount @obsolete @raw-io";
          MemoryDenyWriteExecute = "yes";
          LimitNOFile = 262144;
        };
      };
    };
}
