# NixOS Configuration — Milan's Homelab

## Project Overview
This is a NixOS bare-metal configuration for a high-end workstation used as a homelab.
Hardware: Ryzen 7950X, 96GB RAM, RTX 3090 (headless CUDA/LLM), RX 9070 (display/Wayland/Sunshine).
The system runs K3s cluster with postgresql, kafka, keycloak, kong and microservices with an observability stack (Grafana LGTM + OpenTelemetry), and a Sunshine game streaming server for display output, and to be able
to use RTX 3090 gpu for llm hosting and CUDA workflows in the cluster and outside

## Goals
- Declarative, reproducible system config via NixOS flakes
- K3s cluster management on bare metal (no LXC/VMs)
- Dual GPU: RX 9070 for display+Wayland+Sunshine - but the display setup in that way that I don't need a cable pluggedf into rx 9070 but edid override or virtual display with wlroots
- RTX 3090 headless for CUDA/LLM workloads
- Observability: Grafana, Loki, Tempo, Mimir, Linkerd service mesh
- Remote streaming via Sunshine/Moonlight with NVENC support

## How to Approach Solutions

### Always prefer:
1. Official NixOS documentation first: https://nixos.org/manual/nixos/stable/
2. NixOS options search: https://search.nixos.org/options
3. Nixpkgs source on GitHub: https://github.com/NixOS/nixpkgs
4. NixOS Wiki: https://wiki.nixos.org/
5. Home Manager options (if relevant): https://nix-community.github.io/home-manager/

### Problem-solving principles:
- Always check if a NixOS module already exists before writing custom config
- Prefer `services.*` and `hardware.*` module options over raw systemd units
- When kernel version matters (e.g., NVIDIA), explicitly set `boot.kernelPackages`
- Use `nixpkgs.overlays` or `environment.systemPackages` appropriately
- Prefer flakes + `inputs` for pinning versions
- Never suggest workarounds that break the declarative model (no imperative `apt install` style thinking)

### For GPU/driver issues:
- NVIDIA: use `hardware.nvidia.*` module options, check kernel compat
- AMD: use `hardware.amd.gpu.*` or `services.xserver.videoDrivers`
- When in doubt, check the NixOS NVIDIA wiki page

## Key Files
- `flake.nix` — entry point, inputs, system definitions
- `configuration.nix` — main system config
- `hardware-configuration.nix` — auto-generated, do not edit manually
- `modules/` — custom modular configs (K3s, Sunshine, GPU, etc.)

## Conventions
- Don't change configs without telling me what you are doing and prefer to give me explanation and what to do instead of making the change yourself
- Not everything mentioned is implemented, but we will build it step-by-step so I also gain a mental model of the system I am building
- Don't overdo the config, I want the bare minimum, but the really needed ones for it to work in the described way, and not over the top or speculations