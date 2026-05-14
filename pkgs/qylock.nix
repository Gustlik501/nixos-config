{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:
let
  version = "unstable-2026-05-10";
  src = fetchFromGitHub {
    owner = "Darkkal44";
    repo = "qylock";
    rev = "bece4d25a9dcd043a072847c8ed92dca3800616e";
    hash = "sha256-u1+0dkL4gYyIQP/Ap2cGyf6WhQbUNHxDQDkxT/gbZ1Q=";
  };

  commonMeta = {
    homepage = "https://github.com/Darkkal44/qylock";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
in
{
  assets = stdenvNoCC.mkDerivation {
    pname = "qylock-assets";
    inherit src version;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/qylock"
      cp -r quickshell-lockscreen "$out/share/qylock/quickshell-lockscreen"
      cp -r themes "$out/share/qylock/themes"

      runHook postInstall
    '';

    meta = commonMeta // {
      description = "Qylock quickshell lockscreen assets";
    };
  };

  sddmDogSamuraiTheme = stdenvNoCC.mkDerivation {
    pname = "qylock-sddm-dog-samurai";
    inherit src version;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/sddm/themes"
      cp -r themes/dog-samurai "$out/share/sddm/themes/dog-samurai"

      runHook postInstall
    '';

    meta = commonMeta // {
      description = "Dog Samurai SDDM theme from qylock";
    };
  };
}
