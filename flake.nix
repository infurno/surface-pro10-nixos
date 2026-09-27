{
  description = "Surface Pro 10 for Business - NixOS with niri-tablet & Serpantinum";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    serpantinum = {
      url = "github:ilyamiro/serpantinum";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, disko, home-manager, serpantinum, ... }@inputs:
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
    nixosConfigurations.fury = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs serpantinum; };
      modules = [
        disko.nixosModules.disko
        ./disko.nix
        ./hardware-surface.nix
        ./surface-flex-keyboard.nix
        ./configuration.nix

        serpantinum.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit serpantinum; };
          home-manager.users.hal = import ./home.nix;
        }

        {
          nixpkgs.overlays = [ niriTabletOverlay ];
        }
      ];
    };

    # Alias for backward compatibility
    nixosConfigurations.surface-pro10 = self.nixosConfigurations.fury;
  };
}
