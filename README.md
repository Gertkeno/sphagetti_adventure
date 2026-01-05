# Sphagetti Adventure

A game for Helena, Christmas 2022.

Written in [Zig 0.15.2](https://ziglang.org/download/) for the
[WASM-4](https://wasm4.org) fantasy console.

## Building

Build the cart by running:

```shell
zig build -Doptimize=ReleaseSmall
```

Then run it with:

```shell
w4 run zig-out/lib/cart.wasm
```
