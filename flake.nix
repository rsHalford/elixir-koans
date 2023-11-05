{
  description = "Elixir Koans";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
        elixir = pkgs.elixir_1_15;
      in {
        devShells.default = pkgs.mkShell {
          ERL_AFLAGS = "-kernel shell_history enabled";
          buildInputs = with pkgs;
            [
              elixir
              elixir-ls
              (pkgs.writeShellScriptBin "mix-setup" ''
                if ! test -d $MIX_HOME; then
                  if test -d "$PWD/_backup"; then
                    cp -r _backup/.mix .nix-shell/
                  else
                    yes | ${elixir}/bin/mix local.hex
                  fi
                fi
                if test -f "mix.exs"; then
                  ${elixir}/bin/mix deps.get
                fi
              '')
            ]
            ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.libnotify # For ExUnit Notifier on Linux.
            ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.inotify-tools; # For file_system on Linux.
          shellHook = ''
            if ! test -d .nix-shell; then
              mkdir .nix-shell
            fi
            export NIX_SHELL_DIR=$PWD/.nix-shell
            export MIX_HOME=$NIX_SHELL_DIR/.mix
            export MIX_ARCHIVES=$MIX_HOME/archives
            export HEX_HOME=$NIX_SHELL_DIR/.hex

            export PATH=$MIX_HOME/bin:$PATH
            export PATH=$HEX_HOME/bin:$PATH
            export PATH=$MIX_HOME/escripts:$PATH

            ${elixir}/bin/mix --version
            ${elixir}/bin/iex --version
          '';
        };
      }
    );
}
