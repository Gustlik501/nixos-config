{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "gogcli";
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "steipete";
    repo = "gogcli";
    rev = "v${version}";
    hash = "sha256-hJU40ysjRx4p9SWGmbhhpToYCpk3DcMAWCnKqxHRmh0=";
  };

  vendorHash = "sha256-WGRlv3UsK3SVBQySD7uZ8+FiRl03p0rzjBm9Se1iITs=";

  subPackages = [ "cmd/gog" ];

  ldflags = [
    "-s"
    "-w"
  ];

  meta = with lib; {
    description = "Google Workspace CLI for Gmail, Calendar, Drive, Contacts, Sheets, and Docs";
    homepage = "https://github.com/steipete/gogcli";
    license = licenses.mit;
    mainProgram = "gog";
  };
}
