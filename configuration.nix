{ config, lib, pkgs, ... }: {
  imports = [ <nixpkgs/nixos/modules/virtualisation/amazon-image.nix> ];
  services.hercules-ci-agent.concurrentTasks = 2; # Number of tasks to run simultaneously

  # Room to configure authentication, logging, monitoring etc if desired.
}
