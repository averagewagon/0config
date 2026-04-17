# LLM Server Setup

Steps to set up a RunPod instance as a dedicated LLM inference server, accessible over Tailscale.

## 1. Rent the RunPod instance

Create an account at runpod.io and add ~$10 credit. Click Deploy > GPU Cloud, filter by RTX 5090. Community Cloud is fine for experimenting.

- **Template:** RunPod PyTorch (latest version — comes with CUDA drivers)
- Keep defaults for container disk, volume disk, and everything else
- **Start Jupyter Notebook:** uncheck this
- **SSH Terminal Access:** enable this and upload your public SSH key (useful as a fallback before Tailscale is set up)

Deploy, then SSH in using the command from the RunPod dashboard. Verify the GPU:
```bash
nvidia-smi
```

## 2. Create user (as root)

```bash
useradd -m jhen
passwd jhen
usermod -aG sudo jhen
```

## 3. Install Nix (as root)

RunPod's default mirrors are painfully slow, so we avoid apt entirely by pulling `tailscale` and `pciutils` from Nix. Install Nix first:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
chown -R jhen /nix
```

The installer runs in single-user mode (the container doesn't support multi-user daemon mode); `chown` lets jhen own the store.

## 4. Activate Home Manager (as jhen)

Drop to jhen with a fresh login shell so Nix is on `PATH`:
```bash
su - jhen
```

Clone 0config and switch:
```bash
git clone https://github.com/averagewagon/0config.git
nix-shell -p home-manager --run "home-manager switch --flake ~/0config#llmServer"
```

This installs `tailscale`, `pciutils`, `open-webui`, and the `llm-start` / `llm-stop` wrapper scripts.

## 5. Bring up Tailscale

`tailscaled` needs root (for PAM/SSH integration and state at `/var/lib/tailscale`), but root can execute the Nix-installed binary directly:

```bash
sudo mkdir -p /var/lib/tailscale
sudo /home/jhen/.nix-profile/bin/tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &
sudo /home/jhen/.nix-profile/bin/tailscale up --ssh
```

Authorize the machine via the URL it prints. Optionally rename it in the Tailscale admin console.

## 6. Reconnect via Tailscale SSH (as jhen)

From your laptop:
```bash
ssh jhen@<hostname>
```

## 7. Install Ollama

`lspci` is already on `PATH` from Nix, so the install script's GPU detection works:
```bash
lspci | grep -i nvidia   # sanity check
curl -fsSL https://ollama.com/install.sh | sh
```

Start the services:
```bash
llm-start
```

To stop them later: `llm-stop`

## 8. Verify everything is working

Check both services respond locally:
```bash
curl http://localhost:11434     # → "Ollama is running"
curl -I http://localhost:8080   # → HTTP/1.1 200 OK
```

Pull a small model as a quick sanity check:
```bash
ollama pull qwen3:4b
ollama run qwen3:4b "Write a haiku about GPUs."
```

While it's generating, in another terminal run `nvidia-smi` to confirm the GPU is doing work.

Check it's reachable over Tailscale from your laptop:
```bash
curl http://<hostname>:11434
curl -I http://<hostname>:8080
```

Finally, open `http://<hostname>:8080` in a browser. Open WebUI asks for a name, email, and password on first visit — this is a **local account** stored in the pod's SQLite database, not a cloud signup. Whatever you enter stays on the server. The first account you create is the admin.

## 9. Pull the main model

Once validation is done, pull whatever model you actually want to use:
```bash
ollama pull qwen3.6:35b-a3b
```

If the tag isn't in Ollama's library yet, check `ollama list` or try alternatives like `qwen3-coder:30b`.

## 10. Client setup

**Zed (laptop):** If `llm-client.nix` is in your laptop's Home Manager config, just run `home-manager switch` on the laptop. The Ollama model will appear in Zed's model picker. Update the hostname in `llm-client.nix` if your server has a different Tailscale name.

**Android (Maid):** Install Maid from F-Droid. Go to Settings, choose Ollama as the backend, and set the server URL to `http://<hostname>:11434`.

## 11. Shutting down

**Stop the pod** from the RunPod dashboard when you're done. Billing stops immediately. The volume disk at `/workspace` persists — `llm-server.nix` keeps `ollama-models/` and `open-webui-data/` there, so pulled models and your WebUI account all survive a restart.

When you restart the pod later, you'll need to:
- Re-run Tailscale as root: `sudo /home/jhen/.nix-profile/bin/tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &`
- Re-run `llm-start` as jhen

If you destroy and recreate a pod, it's a fresh setup from step 1 — but the volume disk can be reattached to preserve models.

## Debugging

Check if the services are running:
```bash
pgrep -a ollama
pgrep -a open-webui
curl http://localhost:11434
```

Check GPU utilization while a model is running:
```bash
nvidia-smi
ollama ps
```
