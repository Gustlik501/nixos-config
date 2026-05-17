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

  system.activationScripts.hermesStatePermissions = {
    deps = [ "users" ];
    text = ''
      ${pkgs.coreutils}/bin/install -d -o hermes -g hermes -m 2770 \
        ${stateDir} \
        ${stateDir}/.hermes \
        ${stateDir}/.cache \
        ${workingDirectory}

      ${pkgs.coreutils}/bin/chown -R hermes:hermes -- ${stateDir}
      ${pkgs.coreutils}/bin/chmod -R ug+rwX,o-rwx -- ${stateDir}
      ${pkgs.findutils}/bin/find ${stateDir} -type d -exec ${pkgs.coreutils}/bin/chmod g+s {} +
    '';
  };

  sops.secrets.hermes_env = {
    owner = "hermes";
    group = "hermes";
    mode = "0600";
    restartUnits = [ "hermes-agent.service" ];
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
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
      (python3.withPackages (
        ps:
        let
          ctranslate2-cpp-cuda = pkgs.cudaPackages_12_6.callPackage (
            "${pkgs.path}/pkgs/by-name/ct/ctranslate2/package.nix"
          ) {
            withCUDA = true;
            withCuDNN = true;
          };
          ctranslate2-cuda = ps.ctranslate2.override {
            ctranslate2-cpp = ctranslate2-cpp-cuda;
          };
          faster-whisper-cuda = ps.faster-whisper.override {
            ctranslate2 = ctranslate2-cuda;
          };
        in
        [
          ps.google-api-python-client
          ps.google-auth-oauthlib
          ps.google-auth-httplib2
          faster-whisper-cuda
        ]
      ))
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
