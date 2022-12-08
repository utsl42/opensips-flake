# Nix flake to build and configure [OpenSIPS](https://www.opensips.org)

Builds OpenSIPS with most, but not all modules (excluding Diameter for now).
Configuration module generates loadmodule and modparam directives, sets the
mpath, and supports splitting configuration into multiple files.

See the container configuration defined in the flake for an example.

## Unit test
Run with:

`nix eval .#tests.x86_64-linux.unit-test --json`
