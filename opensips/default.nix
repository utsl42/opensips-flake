{ lib, stdenv, pkgs, fetchFromGitHub }:

let
  extra_modules = "db_postgres httpd json presence presence_dialoginfo pua pua_dialoginfo rls tls_openssl db_mysql db_sqlite pi_http presence_dfks presence_mwi presence_xml proto_tls pua_bla pua_mi pua_usrloc pua_xmpp tls_mgm xcap_client xcap";
in
stdenv.mkDerivation rec {
  pname = "opensips";
  version = "3.3.2";

  src = fetchFromGitHub {
    owner = "OpenSIPS";
    repo = "opensips";
    rev = "ea206a4ad1b01a74888830f8ccbe32a7da43b89a";
    sha256 = "sha256-DZqzqOomz8czxVUIYZl0LxMBMySaPbQgoh2H8gW7Cv0=";
  };

  nativeBuildInputs = with pkgs; [ bison flex which pkg-config ];
  buildInputs = with pkgs; [ ncurses expat openssl postgresql libxml2 libconfuse json_c libmicrohttpd_0_9_72 mysql80 zstd sqlite curl ];

  patchPhase = ''
    # these Makefiles don't use xml-config, so they don't find libxml2's include files. RLS module does, so I copy it, and change the
    # module name.
    sed 's/rls/presence/g' < modules/rls/Makefile > modules/presence/Makefile
    sed 's/rls/presence_dfks/g' < modules/rls/Makefile > modules/presence_dfks/Makefile
    sed 's/rls/presence_dialoginfo/g' < modules/rls/Makefile > modules/presence_dialoginfo/Makefile
    sed 's/rls/presence_xml/g' < modules/rls/Makefile > modules/presence_xml/Makefile
    sed 's/rls/pua_dialoginfo/g' < modules/rls/Makefile > modules/pua_dialoginfo/Makefile
  '';
  buildPhase = ''
    make app
    make modules JSONPATH=${pkgs.json_c} include_modules="${extra_modules}"
  '';
  installPhase = ''
    make install install-modules-all cfg_prefix=$out basedir=$out bin_prefix=$out bin_dir=bin \
      modules_prefix=$out modules_dir=mod map_prefix=$out man_dir=man skip-install-doc=yes \
      include_modules="${extra_modules}"
    # workaround until I figure out where this is controlled in the makefile
    mv $out/usr/local/* $out
    rmdir $out/usr/local
    rmdir $out/usr
    mv $out/etc/opensips/* $out/etc
    rmdir $out/etc/opensips
  '';

  meta = with lib; {
    description = "OpenSIPS - flexible and robust SIP (RFC3261) server";
    homepage = "https://www.opensips.org";
    license = licenses.gpl2;
    platforms = platforms.unix;
  };
}
