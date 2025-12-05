{ lib, stdenv, pkgs, fetchFromGitHub }:

with pkgs.python3Packages;
buildPythonPackage rec {
  pname = "opensips-cli";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "OpenSIPS";
    repo = "opensips-cli";
    rev = "23b93e459b9dfac59949da601308b35e4e845465";
    sha256 = "sha256-vU6WCiv5PtIAvfdRFXzWdCB4itMX/cf/7higrjeO8ng=";
  };

  pyproject = true;
  build-system = [ setuptools ];

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
