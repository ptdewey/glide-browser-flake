# Glide Browser Nix Flake

Nix flake for building and installing the [Glide](https://glide-browser.app/) web browser.

Definitely a WIP, seems to work well enough (but could almost certainly be improved).

## Features

Provides `nix run` and `nix build` commands, as well as a package that can be included as a flake input.

```nix
{
  inputs.glide.url = "github:ptdewey/glide-browser-flake";
  outputs = { nixpkgs, glide, ... }: {
    nixosConfigurations.yourHost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [{
        environment.systemPackages = [
          glide.packages.x86_64-linux.default
        ];
      }];
    };
  };
}
```
