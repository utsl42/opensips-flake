{ lib, stdenv, pkgs, fetchFromGitHub }:

with pkgs.python3Packages;
buildPythonPackage rec {
  pname = "python-opensips";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "OpenSIPS";
    repo = "python-opensips";
    rev = "5a34cda180d303d3bf9dd6be17dcb53a411ecdeb";
    sha256 = "sha256-nlwoG+ipjH36GPhRt9bHcrRZRcy8LtzGFgwyamKXeu4=";
  };

  pyproject = true;
  build-system = [ setuptools ];

  meta = with lib; {
    description = "OpenSIPS Python Packages";
    homepage = "https://www.opensips.org";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
