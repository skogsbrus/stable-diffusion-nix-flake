## Prerequisisites

- Nix (with flakes)
- An NVIDIA GPU

## TODOs

- enable CUDA support for pytorch only, to avoid long build times and broken `cupy` package.

## Usage

### Download the weights

Follow the instructions at
https://huggingface.co/CompVis/stable-diffusion-v-1-4-original.

### Setup

Use `--impure` if you need to enable broken packages.

```
nix develop [--impure]
```

Note that it will take a long time to build packages that use CUDA (opencv, torch).

### Creating images

