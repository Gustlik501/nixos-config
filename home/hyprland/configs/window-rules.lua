-- Window and layer rules.
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Tagging helper: every tag rule below is `match this window -> add this tag`,
-- so the repetition is folded into one function.
local function tag(name, match)
    hl.window_rule({ match = match, tag = name })
end

local function tagClass(name, class)
    tag(name, { class = class })
end

local function tagTitle(name, title)
    tag(name, { title = title })
end

-- browser tags
tagClass("+browser", "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$")
tagClass("+browser", "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$")
tagClass("+browser", "^(chrome-.+-Default)$") -- Chrome PWAs
tagClass("+browser", "^([Cc]hromium)$")
tagClass("+browser", "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$")
tagClass("+browser", "^(Brave-browser(-beta|-dev|-unstable)?)$")
tagClass("+browser", "^([Tt]horium-browser|[Cc]achy-browser)$")
tagClass("+browser", "^(zen-alpha|zen)$")

-- notif tags
tagClass("+notif", "^(swaync-control-center|swaync-notification-window|swaync-client|class)$")

-- KooL settings tags
tagTitle("+KooL_Cheat", "^(KooL Quick Cheat Sheet)$")
tagTitle("+KooL_Settings", "^(KooL Hyprland Settings)$")
tagClass("+KooL-Settings", "^(nwg-displays|nwg-look)$")

-- terminal tags
tagClass("+terminal", "^(Alacritty|kitty|kitty-dropterm)$")

-- email tags
tagClass("+email", "^([Tt]hunderbird|org.gnome.Evolution)$")
tagClass("+email", "^(eu.betterbird.Betterbird)$")

-- project tags
tagClass("+projects", "^(codium|codium-url-handler|VSCodium)$")
tagClass("+projects", "^(VSCode|code-url-handler)$")
tagClass("+projects", "^(jetbrains-.+)$") -- JetBrains IDEs
tagClass("+projects", "^(Kate-.+)$")

-- screenshare tags
tagClass("+screenshare", "^(com.obsproject.Studio)$")

-- IM tags
tagClass("+im", "^([Dd]iscord|[Ww]ebCord)$")
tagClass("+im", "^([Ff]erdium)$")
tagClass("+im", "^([Ww]hatsapp-for-linux)$")
tagClass("+im", "^(ZapZap|com.rtosta.zapzap)$")
tagClass("+im", "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$")
tagClass("+im", "^(teams-for-linux)$")
tagClass("+im", "^(im.riot.Riot|Element)$") -- Element Matrix client

-- game tags
tagClass("+games", "^(gamescope)$")
tagClass("+games", "^(steam_app_\\d+)$")

-- gamestore tags
tagClass("+gamestore", "^([Ss]team)$")
tagTitle("+gamestore", "^([Ll]utris)$")
tagClass("+gamestore", "^(com.heroicgameslauncher.hgl)$")

-- file-manager tags
tagClass("+file-manager", "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$")
tagClass("+file-manager", "^(app.drey.Warp)$")

-- wallpaper tags
tagClass("+wallpaper", "^([Ww]aytrogen)$")

-- multimedia tags
tagClass("+multimedia", "^([Aa]udacious)$")

-- multimedia-video tags
tagClass("+multimedia_video", "^([Mm]pv|vlc)$")

-- settings tags
tagTitle("+settings", "^(ROG Control)$")
tagClass("+settings", "^(wihotspot(-gui)?)$") -- wifi hotspot
tagClass("+settings", "^([Bb]aobab|org.gnome.[Bb]aobab)$") -- disk usage analyzer
tagClass("+settings", "^(gnome-disks|wihotspot(-gui)?)$")
tagTitle("+settings", "(Kvantum Manager)")
tagClass("+settings", "^(file-roller|org.gnome.FileRoller)$") -- archive manager
tagClass("+settings", "^(nm-applet|nm-connection-editor|blueman-manager)$")
tagClass("+settings", "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$")
tagClass("+settings", "^(qt5ct|qt6ct|[Yy]ad)$")
tagClass("+settings", "(xdg-desktop-portal-gtk)")
tagClass("+settings", "^(org.kde.polkit-kde-authentication-agent-1)$")
tagClass("+settings", "^([Rr]ofi)$")

-- viewer tags
tagClass("+viewer", "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$")
tagClass("+viewer", "^(evince)$") -- document viewer
tagClass("+viewer", "^(eog|org.gnome.Loupe)$") -- image viewer

-- Some special override rules
hl.window_rule({ match = { tag = "multimedia_video*" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video*" }, opacity = "1.0" })

-- POSITION
-- Careful: centering every float also centers menus.
-- hl.window_rule({ match = { float = true }, center = true })
hl.window_rule({ match = { tag = "KooL_Cheat*" }, center = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, center = true })
hl.window_rule({ match = { title = "^(ROG Control)$" }, center = true })
hl.window_rule({ match = { tag = "KooL-Settings*" }, center = true })
hl.window_rule({ match = { title = "^(Keybindings)$" }, center = true })
hl.window_rule({ match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = "72% 7%" })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, move = "72% 7%" })

-- Avoid idling for fullscreen apps
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

-- Move to workspace
-- hl.window_rule({ match = { tag = "email*" },       workspace = "1" })
-- hl.window_rule({ match = { tag = "browser*" },     workspace = "2" })
-- hl.window_rule({ match = { class = "^([Tt]hunar)$" }, workspace = "3" })
-- hl.window_rule({ match = { tag = "projects*" },    workspace = "3" })
-- hl.window_rule({ match = { tag = "gamestore*" },   workspace = "5" })
-- hl.window_rule({ match = { tag = "im*" },          workspace = "7" })
-- hl.window_rule({ match = { tag = "games*" },       workspace = "8" })

-- Move to workspace (silent)
-- hl.window_rule({ match = { tag = "screenshare*" },            workspace = "4 silent" })
-- hl.window_rule({ match = { class = "^(virt-manager)$" },      workspace = "6 silent" })
-- hl.window_rule({ match = { class = "^(.virt-manager-wrapped)$" }, workspace = "6 silent" })
-- hl.window_rule({ match = { tag = "multimedia*" },             workspace = "9 silent" })

-- FLOAT
hl.window_rule({ match = { tag = "KooL_Cheat*" }, float = true })
hl.window_rule({ match = { tag = "wallpaper*" }, float = true })
hl.window_rule({ match = { tag = "settings*" }, float = true })
hl.window_rule({ match = { tag = "viewer*" }, float = true })
hl.window_rule({ match = { tag = "KooL-Settings*" }, float = true })
hl.window_rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)$" }, float = true })
hl.window_rule({ match = { class = "(org.gnome.Calculator)", title = "(Calculator)" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
-- hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, float = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, float = true })

-- Float popups and dialogues
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true })
hl.window_rule({ match = { title = "^(Authentication Required)$" }, center = true })
hl.window_rule({ match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" }, float = true })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$", title = "negative:(Heroic Games Launcher)" }, float = true })
hl.window_rule({ match = { class = "^([Ss]team)$", title = "negative:^([Ss]team)$" }, float = true })
hl.window_rule({ match = { class = "([Tt]hunar)", title = "negative:(.*[Tt]hunar.*)" }, float = true })

hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, size = "70% 60%" })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, center = true })

hl.window_rule({ match = { title = "^(Save As)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)$" }, size = "70% 60%" })
hl.window_rule({ match = { title = "^(Save As)$" }, center = true })

hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true })
hl.window_rule({ match = { initial_title = "(Open Files)" }, size = "70% 60%" })

-- KooL's Dots YAD for setting the SDDM background
hl.window_rule({ match = { title = "^(SDDM Background)$" }, float = true })
hl.window_rule({ match = { title = "^(SDDM Background)$" }, center = true })
hl.window_rule({ match = { title = "^(SDDM Background)$" }, size = "16% 12%" })

hl.window_rule({ match = { class = "^(vesktop)$" }, opacity = "1.2 1.2" })

-- OPACITY
hl.window_rule({ match = { tag = "browser*" }, opacity = "1.2 1.2" })
hl.window_rule({ match = { tag = "projects*" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "im*" }, opacity = "1.0 1.0" })
hl.window_rule({ match = { tag = "multimedia*" }, opacity = "0.94 0.86" })
hl.window_rule({ match = { tag = "file-manager*" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { tag = "terminal*" }, opacity = "0.95 0.85" })
hl.window_rule({ match = { tag = "settings*" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { tag = "viewer*" }, opacity = "0.82 0.75" })
hl.window_rule({ match = { tag = "wallpaper*" }, opacity = "0.9 0.7" })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = "0.8 0.7" })
hl.window_rule({ match = { class = "^(deluge)$" }, opacity = "0.9 0.8" })
hl.window_rule({ match = { class = "^(seahorse)$" }, opacity = "0.9 0.8" }) -- gnome-keyring gui
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "0.95 0.75" })

-- SIZE
hl.window_rule({ match = { tag = "KooL_Cheat*" }, size = "65% 90%" })
hl.window_rule({ match = { tag = "wallpaper*" }, size = "70% 70%" })
hl.window_rule({ match = { tag = "settings*" }, size = "70% 70%" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, size = "60% 70%" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, size = "60% 70%" })

-- hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, size = "25% 25%" })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, size = "25% 25%" })

-- PINNING
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true })
-- hl.window_rule({ match = { title = "^(Firefox)$" }, pin = true })

-- Extras
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, keep_aspect_ratio = true })

-- BLUR & FULLSCREEN
hl.window_rule({ match = { tag = "games*" }, no_blur = true })
hl.window_rule({ match = { tag = "games*" }, fullscreen = true })
-- hl.window_rule({ match = { class = "^(steam_app_)" }, monitor = "DP-1" })

-- hl.window_rule({ match = { fullscreen = true }, border_color = "rgb(EE4B55) rgb(880808)" })
-- hl.window_rule({ match = { float = true },      border_color = "rgb(282737) rgb(1E1D2D)" })
-- hl.window_rule({ match = { pin = true },        opacity = "0.8 0.8" })

-- LAYER RULES
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0.5 })
