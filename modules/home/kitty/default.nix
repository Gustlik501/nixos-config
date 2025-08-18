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
      url_color = "#d65c0d"; # last value in your config wins
      url_style = "curly";

      scrollback_lines = 1500;
      wheel_scroll_multiplier = 10.0;

      background_opacity = "1";
      hide_window_decorations = "yes";
      sync_to_monitor = "yes";

      enable_audio_bell = "no";

      # Colors
      cursor = "#928374";
      cursor_text_color = "background";

      visual_bell_color = "#8ec07c";
      bell_border_color = "#8ec07c";

      active_border_color = "#d3869b";
      inactive_border_color = "#665c54";

      active_tab_foreground = "#fbf1c7";
      active_tab_background = "#665c54";
      inactive_tab_foreground = "#a89984";
      inactive_tab_background = "#3c3836";

      foreground = "#ebdbb2";
      background = "#272727";
      selection_foreground = "#655b53";
      selection_background = "#ebdbb2";

      # Palette
      color0  = "#272727";
      color8  = "#928373";

      color1  = "#cc231c";
      color9  = "#fb4833";

      color2  = "#989719";
      color10 = "#b8ba25";

      color3  = "#d79920";
      color11 = "#fabc2e";

      color4  = "#448488";
      color12 = "#83a597";

      color5  = "#b16185";
      color13 = "#d3859a";

      color6  = "#689d69";
      color14 = "#8ec07b";

      color7  = "#a89983";
      color15 = "#ebdbb2";
    };

    keybindings = {
      "ctrl+shift+f" = "send_text all clear\n cd `cdinteractive`\n";
    };
  };
}
