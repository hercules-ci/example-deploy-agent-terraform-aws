{ config, lib, pkgs, ... }: {
  services.hercules-ci-agent.concurrentTasks = 2; # Number of tasks to run simultaneously

  # Room to configure authentication, logging, monitoring etc as desired.
}
