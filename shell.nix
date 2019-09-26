{ pkgs ? import ./nix {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.niv
    pkgs.jq
    pkgs.terraform
  ];
  source_terraform_hercules_ci = toString (import ./nix/sources.nix)."terraform-hercules-ci";
}