# NordVPN Meshnet Docker Compose

This project runs the NordVPN Linux client inside Docker and enables Meshnet automatically when the container starts.

Container image:

- `ghcr.io/qudy2001/nordvpnmeshnet:latest`

It is set up around two current NordVPN requirements:

- the container keeps a fixed hostname so the Meshnet hostname does not change after restarts
- the container gets `NET_ADMIN`, `/dev/net/tun`, and `net.ipv6.conf.all.disable_ipv6=0`

## Runtime

For deployment, you only need `docker-compose.yml`.

The stack pulls the prebuilt GHCR image by default, so there is no local Docker build step.

## Quick start

Make sure your Docker engine is running before you start the stack.

1. Set your token in the shell or in a local `.env` file:

   ```bash
   export NORDVPN_TOKEN=YOUR_NORDVPN_ACCESS_TOKEN
   ```

2. Optionally override defaults such as:

   ```bash
   export NORDVPN_HOSTNAME=meshnet-node
   export TZ=Europe/London
   export NORDVPN_MESHNET=on
   ```

3. Or create a token file instead:

   ```bash
   mkdir -p secrets
   printf '%s\n' 'YOUR_NORDVPN_ACCESS_TOKEN' > secrets/nordvpn_token
   ```

4. Start the stack:

   ```bash
   docker compose up -d
   ```

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
docker compose --profile example up -d
```

Any service that should be reachable through Meshnet can use:

```yaml
network_mode: "service:nordvpn"
```

That way, the service listens on the same Meshnet address as the `nordvpn` container.

## Troubleshooting

- If `docker compose up` fails with a `/dev/net/tun` error, move the stack to a Linux Docker host or Linux VM. NordVPN's Docker setup is documented for Linux containers.

## GitHub Container Registry

The repo still includes the Docker build files for maintainers who want to republish the image.

Build and push manually:

```bash
docker build -t ghcr.io/qudy2001/nordvpnmeshnet:latest -f nordvpn/Dockerfile .
echo "$CR_PAT" | docker login ghcr.io -u qudy2001 --password-stdin
docker push ghcr.io/qudy2001/nordvpnmeshnet:latest
```
