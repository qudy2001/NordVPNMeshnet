# NordVPN Meshnet Docker Compose

This project runs the NordVPN Linux client inside Docker and enables Meshnet automatically when the container starts.

Container image:

- `ghcr.io/qudy2001/nordvpnmeshnet:latest`

It is set up around two current NordVPN requirements:

- the container keeps a fixed hostname so the Meshnet hostname does not change after restarts
- the container gets `NET_ADMIN`, `/dev/net/tun`, and `net.ipv6.conf.all.disable_ipv6=0`

## Files

- `docker-compose.yml`: the main Meshnet stack
- `nordvpn/Dockerfile`: builds the image from the current NordVPN Linux package repo
- `nordvpn/entrypoint.sh`: starts the daemon, logs in with a token, and enables Meshnet
- `.env.example`: runtime settings you can copy into `.env`

## Quick start

Make sure your Docker engine is running before you start the stack.

1. Copy the environment template:

   ```bash
   cp .env.example .env
   ```

2. Pick a stable value for `NORDVPN_HOSTNAME` in `.env`.

3. Create a token file:

   ```bash
   mkdir -p secrets
   printf '%s\n' 'YOUR_NORDVPN_ACCESS_TOKEN' > secrets/nordvpn_token
   ```

4. Start the stack:

   ```bash
   docker compose up -d --build
   ```

   Or pull the prebuilt image from GHCR after switching the Compose file to use `image: ghcr.io/qudy2001/nordvpnmeshnet:latest`.

5. Check the Meshnet node details:

   ```bash
   docker compose exec nordvpn nordvpn meshnet peer list
   docker compose exec nordvpn nordvpn account
   ```

## Optional settings

- `NORDVPN_CONNECT=gb1234`: also connect the container to a VPN server after login
- `NORDVPN_LAN_DISCOVERY=enable`: allow LAN traffic when you also use the VPN tunnel
- `NORDVPN_EXTRA_SUBNETS=192.168.1.0/24,10.0.0.0/16`: allow additional subnets
- `NORDVPN_EXTRA_PORTS=80,443,8080`: allow incoming ports through NordVPN's allowlist

## Running another service through Meshnet

The Compose file includes an optional `example-app` profile that shares the NordVPN network namespace:

```bash
docker compose --profile example up -d --build
```

Any service that should be reachable through Meshnet can use:

```yaml
network_mode: "service:nordvpn"
```

That way, the service listens on the same Meshnet address as the `nordvpn` container.

## Troubleshooting

- If `docker compose up` fails with a `/dev/net/tun` error, move the stack to a Linux Docker host or Linux VM. NordVPN's Docker setup is documented for Linux containers.

## GitHub Container Registry

Build and push manually:

```bash
docker build -t ghcr.io/qudy2001/nordvpnmeshnet:latest -f nordvpn/Dockerfile .
echo "$CR_PAT" | docker login ghcr.io -u qudy2001 --password-stdin
docker push ghcr.io/qudy2001/nordvpnmeshnet:latest
```
