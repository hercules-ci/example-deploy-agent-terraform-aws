{ config, lib, pkgs, ... }: {
  services.hercules-ci-agent.concurrentTasks = 2; # Number of tasks to run simultaneously
  services.hercules-ci-agent.extraOptions.apiBaseUrl = "https://hercstg.com";

  # Room to configure authentication, logging, monitoring etc as desired.
}
