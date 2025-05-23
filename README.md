# Simple_VPN

## Overview

Simple_VPN is a lightweight, automated WireGuard VPN setup script designed for Debian-based systems. It's perfect for securely connecting to your home network from anywhere in the world.

> Note:
For a more feature-rich VPN setup, consider using PiVPN. It works with both WireGuard and OpenVPN, and runs on Raspberry Pi or any Debian-based server.

---

## Features

One-command WireGuard server installation

Automatic detection of dynamic public IP

Optional DuckDNS (Dynamic DNS) integration

Interactive creation of multiple VPN clients

QR code generation for easy mobile client setup



---

## Setup Instructions

1. Upload the setup-wireguard-full.sh script to your Raspberry Pi or other Debian-based Linux device.


2. Make the script executable:

```bash
chmod +x setup-wireguard-full.sh
```

3. Run the script with root privileges:
```bash
sudo ./setup-wireguard-full.sh
```



---

## Final Notes

Ensure port forwarding is enabled on your router (default: UDP 51820)

Back up your client configuration files

Enjoy secure and private remote access to your network