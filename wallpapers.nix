{ config, pkgs, lib, ... }:

let
  urls = [
    "https://w.wallhaven.cc/full/yq/wallhaven-yqkl97.jpg"
    "https://w.wallhaven.cc/full/q6/wallhaven-q6wz6r.jpg"
  ];
  dir = "${config.home.homeDirectory}/Pictures/Wallpapers";
in
{
  home.activation.wallpapers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${dir}
    ${lib.concatMapStringsSep "\n" (url: ''
      f="${dir}/${builtins.baseNameOf url}"
      [ -e "$f" ] || ${pkgs.curl}/bin/curl -fsSL -o "$f" ${lib.escapeShellArg url}
    '') urls}
  '';
}
