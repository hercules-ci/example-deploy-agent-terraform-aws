# This project uses the Nixpkgs version from terraform-hercules-ci
{ sources ? import ./sources.nix
, pkgs ? import (sources.terraform-hercules-ci + "/nix") {
    extraOverlays = [
      (self: super: {
        terraform = super.terraform.withPlugins (import ./terraform-plugins.nix super);
      })
    ];
  }
}:
pkgs
