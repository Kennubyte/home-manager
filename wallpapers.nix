{ config, pkgs, lib, ... }:

let
  urls = [
    "https://w.wallhaven.cc/full/yq/wallhaven-yqkl97.jpg"
    "https://w.wallhaven.cc/full/q6/wallhaven-q6wz6r.jpg"
  ];
in
{
  home.file = builtins.listToAttrs (map (url: {
    name = "Pictures/Wallpapers/${builtins.baseNameOf url}";
    value = {
      source = pkgs.fetchurl {
        inherit url;
      };
    };
  }) urls);
}
