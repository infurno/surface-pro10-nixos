{
  description = "Surface Pro 10 for Business - NixOS with niri-tablet & Flex Keyboard";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, disko, ... }@inputs:
  let
    system = "x86_64-linux";

    # Read all patch files in ./patches in natural sorted order
    patchDir = ./patches;
    patchFileNames = builtins.filter
      (name: nixpkgs.lib.hasSuffix ".patch" name)
      (builtins.attrNames (builtins.readDir patchDir));
    sortedPatchNames = nixpkgs.lib.naturalSort patchFileNames;
    niriTabletPatches = map (name: patchDir + "/${name}") sortedPatchNames;

    # Overlay applying niri-tablet touchscreen patches to upstream niri
    niriTabletOverlay = final: prev: {
      niri-tablet = prev.niri.overrideAttrs (oldAttrs: {
        pname = "niri-tablet";
        patches = (oldAttrs.patches or []) ++ niriTabletPatches;
      });
    };
  in {
    nixosConfigurations.surface-pro10 = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        ./disko.nix
        ./hardware-surface.nix
        ./surface-flex-keyboard.nix
        ./configuration.nix
        {
          nixpkgs.overlays = [ niriTabletOverlay ];
        }
      ];
    };
  };
}
