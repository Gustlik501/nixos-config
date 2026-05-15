{
  config,
  inputs,
  pkgs,
  ...
}:
let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  stateDir = "/data/hermes";
  workingDirectory = "${stateDir}/workspace";
in
{
  systemd.tmpfiles.rules = [
    "z ${stateDir} 2770 hermes hermes -"
    "z ${stateDir}/.hermes 2770 hermes hermes -"
    "z ${workingDirectory} 2770 hermes hermes -"
  ];

  sops.secrets.hermes_env = {
    owner = "hermes";
    group = "hermes";
    mode = "0600";
    restartUnits = [ "hermes-agent.service" ];
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = false;
    inherit stateDir workingDirectory;

    environmentFiles = [
      config.sops.secrets.hermes_env.path
    ];

    environment = {
      HERMES_HEADLESS = "1";
      HERMES_HOME = "${stateDir}/.hermes";
      XDG_CACHE_HOME = "${stateDir}/.cache";
    };

    settings = {
      model = {
        provider = "openai-codex";
        default = "gpt-5.3-codex";
      };

      toolsets = [ "all" ];
      group_sessions_per_user = true;

      terminal = {
        backend = "local";
        cwd = workingDirectory;
        timeout = 180;
      };

      streaming = {
        enabled = true;
        transport = "edit";
      };

      discord = {
        require_mention = true;
        auto_thread = true;
      };

      agent = {
        reasoning_effort = "medium";
      };

      stt = {
        enabled = true;
        provider = "local";
        local = {
          model = "small";
        };
      };
    };

    extraPackages = with pkgs; [
      (python3.withPackages (ps: with ps; [
        google-api-python-client
        google-auth-oauthlib
        google-auth-httplib2
        faster-whisper
      ]))
      ffmpeg
      curl
      fd
      git
      gh
      jq
      nodejs_22
      openssh
      ripgrep
      wget
      gws
      llmAgents.codex
    ];

    extraDependencyGroups = [
      "messaging"
      "voice"
    ];
  };
}
