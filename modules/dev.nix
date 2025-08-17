{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    #git
    #lazygit
    #openssh
    #curl
    #wget
  ];
}
