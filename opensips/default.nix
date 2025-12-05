{ lib, stdenv, pkgs, fetchFromGitHub }:

let
  generic =
    {
      pname,
      version,
      sha256,
      ...
    }@attrs:
    let
      attrs' = builtins.removeAttrs attrs [
        "version"
        "hash"
      ];
      extra_modules = (builtins.concatStringsSep " " [
        "db_postgres"
        "httpd"
        "json"
        "presence"
        "presence_dialoginfo"
        "pua"
        "pua_dialoginfo"
        "rls"
        "tls_openssl"
        "db_mysql"
        "db_sqlite"
        "pi_http"
        "presence_dfks"
        "presence_mwi"
        "presence_xml"
        "proto_tls"
        "pua_bla"
        "pua_mi"
        "pua_usrloc"
        "pua_xmpp"
        "tls_mgm"
        "xcap_client"
        "xcap"
        "event_kafka"
        "cachedb_redis"
        "carrierroute"
        "uuid"
        "rest_client"
        "proto_wss"
        "db_http"
        "rabbitmq"
        "event_rabbitmq"
        "rabbitmq_consumer"
        "lua"
      ]);
    in
        stdenv.mkDerivation rec {
          inherit pname;
          inherit version;
  
          src = fetchFromGitHub {
            owner = "OpenSIPS";
            repo = "opensips";
            rev = "${version}";
            inherit sha256;
          };

          nativeBuildInputs = with pkgs; [ bison flex which pkg-config libxslt lynx ];
          buildInputs = with pkgs; [ ncurses expat openssl postgresql libxml2 libconfuse json_c libmicrohttpd mysql80 zstd sqlite curl rdkafka hiredis libconfuse libuuid rabbitmq-c lua5_1 libmemcached ];

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
            make app VERSIONTYPE=git THISREVISION=${version}
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
        // attrs';
  in
rec {
  opensips_34 = generic {
    pname = "opensips_34";
    version = "3.4.15";
    sha256 = "sha256-O9SAs34tTkgQt8RzeyofSvnCXfRU6+ZWG4nQ6lNtxOw=";
  };

  opensips_35 = generic {
    pname = "opensips_35";
    version = "3.5.8";
    sha256 = "sha256-Y0regsEJgCu9tK4tCAWhgm90xCUe+F6tAOBwyn38vHI=";
  };

  opensips_36 = generic {
    pname = "opensips_36";
    version = "3.6.2";
    sha256 = "sha256-doT1vxQIuEch5jVpVEkXYzMQTKHv8R/T0VtbQPdQVh4=";
  };
}
