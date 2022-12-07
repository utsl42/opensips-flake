{ pkgs }:
let
  inherit (pkgs) lib;
  inherit (lib) runTests;
  configfile = import ./configfile.nix { inherit pkgs; };
  testParams = {
    tm = {
      fr_timeout = 5;
      fr_inv_timeout = 30;
    };
    registrar = {
      attr_avp = "$avp(attr)";
    };
    signaling = { };
  };
in
with configfile; runTests {
  test1 = {
    expr = modParam "test" "a" "b";
    expected = ''modparam("test", "a", "b")'';
  };
  test2 = {
    expr = modParamList "test" { "a" = "b"; "c" = "d"; };
    expected = ''
      modparam("test", "a", "b")
      modparam("test", "c", "d")'';
  };
  test3 = {
    expr = modParamAttrs testParams;
    expected = ''
      modparam("registrar", "attr_avp", "$avp(attr)")
      modparam("tm", "fr_inv_timeout", 30)
      modparam("tm", "fr_timeout", 5)'';
  };
  test4 = {
    expr = loadModules testParams;
    expected = ''
      loadmodule "registrar.so"
      loadmodule "signaling.so"
      loadmodule "tm.so"'';
  };
  test5 = {
    expr = moduleConfiguration testParams;
    expected = ''
      loadmodule "registrar.so"
      loadmodule "signaling.so"
      loadmodule "tm.so"

      modparam("registrar", "attr_avp", "$avp(attr)")
      modparam("tm", "fr_inv_timeout", 30)
      modparam("tm", "fr_timeout", 5)'';
  };
}
