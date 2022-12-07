{ lib, stdenv, pkgs, fetchFromGitHub }:

with pkgs.python3Packages;
buildPythonPackage rec {
  pname = "opensips-cli";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "OpenSIPS";
    repo = "opensips-cli";
    rev = "e4dee4aa9cedb1b24c64210e41863e59b12a094f";
    sha256 = "sha256-I2jStuPm0bZX2F02DvT6/ZJuDI8Kn6+I7uU5aqvAVaQ=";
  };

  propagatedBuildInputs = [ sqlalchemy sqlalchemy-utils ];
  patchPhase = ''
    # The versions of mysqlclient and sqlalchemy this thing wants
    # aren't available. For now, remove these constraints, since
    # we can still use the MI interface without the datbase part.
    sed -i '/mysqlclient/d;s/==1.3.3//g' setup.py
  '';

  meta = with lib; {
    description = "OpenSIPS Command Line Interface";
    homepage = "https://www.opensips.org";
    license = licenses.gpl3;
    platforms = platforms.unix;
  };
}
