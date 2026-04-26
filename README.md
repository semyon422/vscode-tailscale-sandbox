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
- Workspace mount: `/workspaces/home`

## Notes

- `code-server` shares the `tailscale` network namespace, so its traffic uses the exit node.
- The container's Tailscale namespace provides the network sandbox; Codex can use full-access mode inside this already isolated environment.
- `--exit-node-allow-lan-access=true` is required so the host can still reach `127.0.0.1:${CODE_PORT}`.
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
