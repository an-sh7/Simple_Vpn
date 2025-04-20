# Simple_VPN
Works with wireguard to let you connect to your home network from anywhere in the world
Note :- I use on a raspberry pi 4 with ubuntu server on it.
## Instructions

1. Upload `setup-wireguard-full.sh` to your Raspberry Pi or any other debian based linux device.
2. Make it executable:
   ```bash
   chmod +x setup-wireguard-full.sh
   ```
3. Run it as root or using sudo:
   ```bash
   sudo ./setup-wireguard-full.sh
   ```

## Features

- Automatic WireGuard server setup
- Detects dynamic public IP
- Optional DuckDNS (dynamic DNS) setup
- Interactive multiple client creation
- Client configuration with QR codes for easy mobile setup

Enjoy!
