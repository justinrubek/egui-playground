# egui-playground

## use

Obtain a development shell: `nix develop`

From the development shell you may develop as usual run the GUI: `cargo run`


Alternatively, use the flake app: `nix run`

Create a release build: `nix build`

## pre-commit-hooks

The development shell configures pre-commit hooks.
These will check formatting before allowing the commit to be created.

If rustfmt is failing, run `cargo fmt` to automatically format the code.

The hooks will be configured on the local git repo so committing will only work when inside a development shell.

## thanks

I was able to get this flake working thanks to this post [https://scvalex.net/posts/63/](https://scvalex.net/posts/63/)
