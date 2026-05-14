{ lib, pkgs, ... }:
let
  themeName = "dog-samurai";
  qylockRoot = "${pkgs.qylockAssets}/share/qylock";
  qylockLockscreenDir = "${qylockRoot}/quickshell-lockscreen";
  qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" [
    pkgs.qt6.qt5compat
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtmultimedia
  ];
  qtPluginPath = lib.makeSearchPath "lib/qt-6/plugins" [
    pkgs.qt6.qt5compat
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtmultimedia
    pkgs.qt6.qtsvg
  ];
  gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0" [
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
    pkgs.gst_all_1.gst-plugins-bad
    pkgs.gst_all_1.gst-plugins-ugly
  ];
  qylockLock = pkgs.writeShellApplication {
    name = "qylock-lock";
    runtimeInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.hyprland
      pkgs.psmisc
      pkgs.quickshell
      pkgs.systemd
    ];
    text = ''
      theme="''${1:-${themeName}}"

      export QML2_IMPORT_PATH="${qylockLockscreenDir}/imports:${qmlImportPath}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
      export QT_PLUGIN_PATH="${qtPluginPath}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
      export GST_PLUGIN_SYSTEM_PATH_1_0="${gstPluginPath}''${GST_PLUGIN_SYSTEM_PATH_1_0:+:$GST_PLUGIN_SYSTEM_PATH_1_0}"
      export QML_XHR_ALLOW_FILE_READ=1
      export XDG_SESSION_TYPE="''${XDG_SESSION_TYPE:-wayland}"
      export QS_THEME="$theme"
      export QS_THEME_PATH="${qylockRoot}/themes/$theme"

      killall -9 hyprlock swaylock wlogout 2>/dev/null || true

      if command -v quickshell >/dev/null 2>&1; then
        exec quickshell -p "${qylockLockscreenDir}/lock_shell.qml"
      elif command -v qs >/dev/null 2>&1; then
        exec qs -p "${qylockLockscreenDir}/lock_shell.qml"
      else
        echo "qylock: neither quickshell nor qs is available" >&2
        exit 1
      fi
    '';
  };
in
{
  home.packages = [ qylockLock ];

  xdg.configFile."qylock/theme".text = "${themeName}\n";
}
