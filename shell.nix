let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/master";
  pkgs = import nixpkgs { config = { allowUnfree = true; }; overlays = []; };
in

pkgs.mkShellNoCC {
  packages = with pkgs; [
    go
  ];
  LANGUAGE="en_US";
  shellHook = ''
    clear
    go mod tidy
    go mod vendor
  '';
}

