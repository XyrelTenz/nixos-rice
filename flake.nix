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
  };

  outputs = inputs@{ self, nixpkgs, hyprland, home-manager, antigravity-nix, ... }: {
    nixosConfigurations.XyrelTenz = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        hyprland.nixosModules.default
        ./hardware-configuration.nix
        ./configuration.nix

        # Home Manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.xyreltenz = import ./home.nix;
        }

        {
          environment.systemPackages = [
            antigravity-nix.packages.x86_64-linux.google-antigravity-ide
          ];
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}
