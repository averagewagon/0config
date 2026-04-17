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

## 3. Install Tailscale (as root)

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

RunPod containers don't have systemd as init or the TUN device, so start
Tailscale manually with userspace networking:
```bash
tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &
tailscale up --ssh
```

Authorize the machine via the URL it prints. Optionally rename it in the Tailscale admin console to whatever you like.

## 4. Reconnect via Tailscale SSH (as jhen)

```bash
ssh jhen@<hostname>
```

## 5. Install Nix and activate Home Manager

Clone 0config (public repo, no SSH key needed):
```bash
git clone https://github.com/averagewagon/0config.git
```

Install Nix (as root, since the container doesn't support multi-user daemon mode):
```bash
sudo su -c 'curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install'
sudo chown -R jhen /nix
```

Restart the shell, then activate:
```bash
nix-shell -p home-manager
home-manager switch --flake ~/0config#llmServer
```

## 6. Install Ollama

The install script uses `lspci` to detect the GPU; install it first so CUDA
support gets pulled in correctly:
```bash
sudo apt-get install -y pciutils
```

Verify `lspci` shows your GPU:
```bash
lspci | grep -i nvidia
```

Then install Ollama (the script handles CUDA detection automatically):
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Start the services using the wrapper script from `llm-server.nix`:
```bash
llm-start
```

To stop them later: `llm-stop`

## 7. Verify everything is working

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

## 8. Pull the main model

Once validation is done, pull whatever model you actually want to use:
```bash
ollama pull qwen3.6:35b-a3b
```

If the tag isn't in Ollama's library yet, check `ollama list` or try alternatives like `qwen3-coder:30b`.

## 9. Client setup

**Zed (laptop):** If `llm-client.nix` is in your laptop's Home Manager config, just run `home-manager switch` on the laptop. The Ollama model will appear in Zed's model picker. Update the hostname in `llm-client.nix` if your server has a different Tailscale name.

**Android (Maid):** Install Maid from F-Droid. Go to Settings, choose Ollama as the backend, and set the server URL to `http://<hostname>:11434`.

## 10. Shutting down

**Stop the pod** from the RunPod dashboard when you're done. Billing stops immediately. The volume disk (with your models) persists.

When you restart the pod later, you'll need to:
- Re-run Tailscale as root: `tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state &`
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
