final: prev: {
  # Import the logic from the top-level overlay and assign its result to the 'francynox' namespace.
  francynox = (import ./flat.nix) final prev;
}
