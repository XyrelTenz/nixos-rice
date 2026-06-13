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
    qylock = {
      url = "github:Darkkal44/qylock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
      # Do NOT follow nixpkgs — version must match what was used to build the cache
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    hyprland,
    home-manager,
    antigravity-nix,
    qylock,
    nix-cachyos-kernel,
    ...
  }: {
    nixosConfigurations.XyrelTenz = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        # 2. Add the module here
        qylock.nixosModules.default

        hyprland.nixosModules.default
        ./hardware-configuration.nix
        ./configuration.nix

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

        # CachyOS kernel overlay — exposes pkgs.cachyosKernels.*
        {
          nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
        }
      ];
    };
  };
}
