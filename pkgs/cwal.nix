{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  imagemagick,
  libimagequant,
  lua,
}:
stdenv.mkDerivation rec {
  pname = "cwal";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "nitinbhat972";
    repo = "cwal";
    rev = "v${version}";
    hash = "sha256-H7liUw/KUT8U0KxBbUFvfu+L1vD7CbGw0cjbwjwwKrY=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    imagemagick
    libimagequant
    lua
  ];

  meta = with lib; {
    description = "Blazing-fast pywal-like color palette generator written in C";
    homepage = "https://github.com/nitinbhat972/cwal";
    license = licenses.gpl3Only;
    mainProgram = "cwal";
    platforms = platforms.linux;
  };
}
