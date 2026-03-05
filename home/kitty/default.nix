{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 12;
    };

    settings = {
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      window_padding_width = 25;
      confirm_os_window_close = 0;

      detect_urls = "yes";
      url_style = "curly";

      scrollback_lines = 1500;
      wheel_scroll_multiplier = 10.0;

      background_opacity = "1";
      hide_window_decorations = "yes";
      sync_to_monitor = "yes";

      enable_audio_bell = "no";
    };

    extraConfig = ''
      # Override static fallback palette with the last generated cwal palette.
      include ~/.cache/wal/colors-kitty.conf
    '';

    keybindings = {
      "ctrl+shift+f" = "send_text all clear\n cd `cdinteractive`\n";
      "ctrl+c" = "copy_or_interrupt";
      "ctrl+v" = "paste_from_clipboard";
    };
  };

  #set kitty as TerminalEmulator
  xdg.desktopEntries.kitty = {
    name = "Kitty";
    exec = "kitty";
    terminal = false;
    type = "Application";
    icon = "kitty";
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };

  # Set kitty as default of xfce
  xdg.configFile."xfce4/helpers.rc".text = ''
    TerminalEmulator=kitty
  '';

}
