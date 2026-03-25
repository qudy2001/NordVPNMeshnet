# NordVPN Meshnet Compose

This repo is intentionally minimal. For deployment, you only need `docker-compose.yml` and a NordVPN access token.

Image:

- `ghcr.io/qudy2001/nordvpnmeshnet:latest`

## Start

1. Put your token in the shell or in a local `.env` file:

   ```bash
   export NORDVPN_TOKEN=YOUR_NORDVPN_ACCESS_TOKEN
   ```

2. Start the stack:

   ```bash
   docker compose up -d
   ```

3. Check the node:

   ```bash
   docker compose exec nordvpn nordvpn account
   docker compose exec nordvpn nordvpn meshnet peer list
   ```

## Optional settings

- `NORDVPN_HOSTNAME=meshnet-node`
- `TZ=Europe/London`
- `NORDVPN_MESHNET=on`
- `NORDVPN_LAN_DISCOVERY=enable`
- `NORDVPN_CONNECT=gb1234`
- `NORDVPN_EXTRA_SUBNETS=192.168.1.0/24,10.0.0.0/16`
- `NORDVPN_EXTRA_PORTS=80,443,8080`
- `NORDVPN_ALLOW_ROUTING_PEERS=peer-one.nord,peer-two.nord`
- `NORDVPN_ALLOW_LOCAL_PEERS=peer-one.nord`
- `NORDVPN_ALLOW_ALL_ROUTING=on`
- `NORDVPN_ALLOW_ALL_LOCAL=on`

You can also use a token file by creating `secrets/nordvpn_token`.

If you set `NORDVPN_ALLOW_ROUTING_PEERS`, the container will automatically run `nordvpn meshnet peer routing allow` for those peers on startup.

If you set `NORDVPN_ALLOW_LOCAL_PEERS`, the container will automatically grant both traffic routing and local network access for those peers.

If you set `NORDVPN_ALLOW_ALL_ROUTING=on`, the container will attempt to allow traffic routing for every currently linked Meshnet peer on startup.

If you set `NORDVPN_ALLOW_ALL_LOCAL=on`, the container will attempt to allow both traffic routing and local network access for every currently linked Meshnet peer on startup.

## Notes

- The container needs `NET_ADMIN`, `/dev/net/tun`, and `net.ipv6.conf.all.disable_ipv6=0`.
- If `/dev/net/tun` is not available, run this on a Linux Docker host or Linux VM.
