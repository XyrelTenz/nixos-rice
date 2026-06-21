{
  description = "NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };
    matugen = {
      url = "github:InioX/matugen";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    hyprland,
    home-manager,
    antigravity-nix,
    silentSDDM,
    nix-cachyos-kernel,
    ...
  }: let
    username = "xyreltenz";
    timezone = "Asia/Manila";
  in {
    nixosConfigurations.XyrelTenz = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs username timezone; };
      modules = [
        silentSDDM.nixosModules.default

        hyprland.nixosModules.default
        ./hardware-configuration.nix
        ./configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs username; };
          home-manager.users.${username} = import ./home.nix;
        }

        {
          environment.systemPackages = [
            antigravity-nix.packages.x86_64-linux.google-antigravity-ide
          ];
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.android_sdk.accept_license = true;
        }
        {
          nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
        }
      ];
    };
  };
}
