{ pkgs }:
let
  inherit (pkgs) lib;
in
rec {
  /* Convert module, key, and value to an OpenSIPS modparam */
  modParam = m: k: v:
    if builtins.isInt v then
      ''modparam("${m}", "${k}", '' + builtins.toString v + ")"
    else
      ''modparam("${m}", "${k}", "${v}")'';
  /* Map a module's attribute set to modparam */
  modParamList = m: kv: lib.concatStringsSep "\n" (lib.mapAttrsToList (modParam m) kv);
  /* Map a nested attribute of modules and key/value parameters to a list of OpenSIPS modparam configurations */
  modParamAttrs = attrs: lib.concatStringsSep "\n" (lib.remove "" (lib.mapAttrsToList modParamList attrs));
  /* Map an attribute set to OpenSIPS loadmodule configurations */
  loadModules = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList (m: _: ''loadmodule "${m}.so"'') attrs);

  moduleConfiguration = attrs: lib.concatStringsSep "\n\n" [ (loadModules attrs) (modParamAttrs attrs) ];
}
