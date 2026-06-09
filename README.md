# VS Code Tailscale Sandbox

Docker-based VS Code sandbox where editor traffic goes through a dedicated Tailscale client using an exit node, while your host home directory stays accessible for normal development work.

## Setup

```bash
cp .env.example .env
```

Required `.env` values:

```env
TS_AUTHKEY=your-tailscale-auth-key
TS_EXIT_NODE=exit-node-name-or-100.x.y.z
CODE_PASSWORD=change-this
CODE_PORT=8443
UID=1000
GID=1000
USER_NAME=youruser
TZ=Europe/Moscow
```

Optional local mounts can be added with a gitignored Compose override:

```bash
cp docker-compose.override.yml.example docker-compose.override.yml
```

Edit the copied file with any host-to-container bind mounts you want, for example `/path/on/host:/path/in/container`.

## Run

```bash
docker compose up -d --build
```

Or:

```bash
./restart
```

If you start the stack with plain `docker compose up`, apply LAN route exceptions after startup with:

```bash
./apply-lan-routes
```

That helper is currently hardcoded for the working route on this machine:

```bash
docker exec ts-code ip route add 192.168.1.0/24 via 172.19.0.1 dev eth0 table 52
docker exec ts-code ip route add 192.168.1.0/24 via 172.19.0.1 dev eth0
```

Check status:

```bash
./check
docker compose ps
```

Stop:

```bash
./stop
```

## Installing packages

The `code-server` container is built from the local `Dockerfile`. Add Debian packages to the `apt-get install` list, then rebuild:

```bash
docker compose up -d --build
```

The `./restart` helper also rebuilds the image before starting the sandbox.

## Access

- Browser: `http://127.0.0.1:${CODE_PORT}`
- Local network: `http://<host-lan-ip>:${CODE_PORT}`
- Workspace mount: `/workspaces/home`

## Notes

- `code-server` shares the `tailscale` network namespace, so its traffic uses the exit node.
- The container's Tailscale namespace provides the network sandbox; Codex can use full-access mode inside this already isolated environment.
- `--exit-node-allow-lan-access=true` is required so the host can still reach `127.0.0.1:${CODE_PORT}`.
- Docker already publishes the editor on `0.0.0.0:${CODE_PORT}` and `code-server` itself listens on `0.0.0.0:8080`, so LAN clients must use the host machine's real LAN IP, not `127.0.0.1` or `localhost`.
- When an exit node is active, Tailscale inside the container can only auto-exempt subnets it can see directly. `./apply-lan-routes` hardcodes the working fix for `192.168.1.0/24` so replies to local devices do not get sent back through the exit node.
- The host home directory is mounted by default at `/workspaces/home`.
- Local-only bind mounts can live in `docker-compose.override.yml`; mount host shares before starting or restarting the containers.
- Persistent local state in this repo lives in `code-home/` and `tailscale-state/`.

## Troubleshooting

- If Tailscale login gets stuck, check:
```bash
docker compose logs tailscale
docker exec -it ts-code tailscale --socket=/tmp/tailscaled.sock status
docker exec -it ts-code tailscale --socket=/tmp/tailscaled.sock netcheck
```

- If `http://127.0.0.1:${CODE_PORT}` works on the host but another device on your LAN cannot connect:
```bash
hostname -I
ss -ltnp | grep ":${CODE_PORT}"
sudo ufw status
```
Use the host's LAN IP from `hostname -I`, for example `http://192.168.1.50:${CODE_PORT}`. If the port is listening but still unreachable, the blocker is usually the host firewall, router/AP client isolation, or an extra VM layer such as WSL2 where the port is only forwarded to the host loopback interface.

- If localhost works but the host LAN IP hangs while using an exit node, check Tailscale's route exceptions inside the container:
```bash
docker exec ts-code ip route show table 52
./apply-lan-routes
```
You should see `192.168.1.0/24` routed via the Docker bridge gateway instead of only `127.0.0.0/8` and `172.19.0.0/16`. If your LAN subnet changes, update `./apply-lan-routes`.

- If container egress looks broken, test Docker networking first:
```bash
sudo docker run --rm --network bridge alpine ping -c 2 8.8.8.8
sudo docker run --rm --network bridge alpine nslookup controlplane.tailscale.com 1.1.1.1
```

## OpenAI Codex Extension

If you install the OpenAI Codex extension inside browser `code-server`:

- Set Codex permissions to `Full access`; this avoids Codex's inner Linux sandbox while the Docker/Tailscale container remains the network sandbox.
- VS Code forwards the local auth port automatically
- When prompted for the callback URL, use `http://127.0.0.1:${CODE_PORT}/proxy/1455/` instead of `http://localhost:1455`

## pi Coding Agent with LM Studio

To use the [pi coding agent](https://pi.dev/) with [LM Studio](https://lmstudio.ai/) as the local LLM provider configure the pi agent via `~/.pi/agent/models.json`:

```json
{
  "providers": {
    "lmstudio": {
      "baseUrl": "http://host.docker.internal:1234/v1",
      "api": "openai-completions",
      "apiKey": "lm-studio",
      "models": [
        {
          "id": "qwen/qwen3.6-35b-a3b",
          "input": [
            "text",
            "image"
          ]
        }
      ]
    }
  }
}
```
