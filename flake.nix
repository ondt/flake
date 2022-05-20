{
	description = "ondt's Nix Flake";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

		home-manager.url = "github:nix-community/home-manager";
		home-manager.inputs.nixpkgs.follows = "nixpkgs";
	};

	outputs = { self, nixpkgs, ... } @ inputs: let
		inherit (lib.my) mapModules mapModulesRec mapHosts;
		system = "x86_64-linux";

		mkPkgs = pkgs: extraOverlays: import pkgs {
			inherit system;
			config.allowUnfree = true;
			overlays = extraOverlays ++ (lib.attrValues self.overlays);
		};

		pkgs = mkPkgs nixpkgs [ self.overlays.default ];

		lib = nixpkgs.lib.extend (self: super: {
			my = import ./lib { inherit pkgs inputs; lib = self; };
		});

	in {
		lib = lib.my;

		overlays = (mapModules ./overlays import) // {
			default = final: prev: {
				my = self.packages.${system};
			};
		};

		packages.${system} = mapModules ./packages (p: pkgs.callPackage p {});

		nixosModules = { dotfiles = import ./.; } // mapModulesRec ./modules import;

		nixosConfigurations = mapHosts ./hosts {};

	};
}
