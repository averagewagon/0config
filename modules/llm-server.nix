{
  pkgs,
  ...
}:

{
  allowedUnfreePackages = [ "open-webui" ];

  home.packages = with pkgs; [
    open-webui
    tailscale
    pciutils # provides lspci, needed by Ollama's install script for GPU detection

    # Wrapper scripts for starting services in containers without systemd.
    # Ollama itself is installed via the official install script (see
    # LLM_SERVER_SETUP.md), not Nix, because CUDA detection on non-NixOS is
    # unreliable with the nix-packaged ollama-cuda.
    (pkgs.writeShellScriptBin "llm-start" ''
      # Keep model weights and WebUI data on the RunPod volume (/workspace),
      # not on the tiny container overlay disk.
      mkdir -p /workspace/ollama-models /workspace/open-webui-data

      echo "Starting Ollama..."
      OLLAMA_HOST=0.0.0.0:11434 \
      OLLAMA_MODELS=/workspace/ollama-models \
      /usr/local/bin/ollama serve &
      sleep 2

      echo "Starting Open WebUI..."
      OLLAMA_BASE_URL=http://localhost:11434 \
      DATA_DIR=/workspace/open-webui-data \
      HOST=0.0.0.0 \
      PORT=8080 \
      ${pkgs.open-webui}/bin/open-webui serve &

      echo "Services started. Ollama on :11434, Open WebUI on :8080"
    '')
    (pkgs.writeShellScriptBin "llm-stop" ''
      echo "Stopping services..."
      pkill -f "ollama serve" 2>/dev/null
      pkill -f "open-webui serve" 2>/dev/null
      echo "Done."
    '')
  ];
}
