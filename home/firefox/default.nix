{ pkgs, ... }:
{
  home.packages = [ pkgs.pywalfox-native ];

  home.file.".mozilla/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
    name = "pywalfox";
    description = "Pywalfox Native";
    path = "${pkgs.pywalfox-native}/bin/pywalfox";
    type = "stdio";
    allowed_extensions = [ "pywalfox@frewacom.org" ];
  };

  programs.firefox = {
    enable = true;

    nativeMessagingHosts = [ pkgs.pywalfox-native ];

    policies = {
      ExtensionSettings = {
        "pywalfox@frewacom.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
          default_area = "navbar";
        };
      };
    };

    profiles.default = {
      id = 0;
      isDefault = true;
    };
  };
}
