# mobile-GLiNET.sh

This Bash script configures a network interception setup using a GL.iNet travel router connected via Ethernet (eth1), allowing traffic from a connected device to be intercepted and analyzed through **Burp Suite**.

The script is designed for environments where the analyzing machine is:
- Connected to the Internet via VPN (`tun0`)
- Connected to BurpSuite via `eth0`
- Connected to a GL.iNet router (typically `eth1`) that acts as a gateway for a victim device (e.g., a smartphone)

## 🛠 Features

- Automatically checks root privileges and tool dependencies
- Verifies physical link status on `eth1`
- Assigns IP to `eth1` if missing
- Enables IP forwarding
- Configures `iptables` rules to:
  - Allow and route traffic from a victim device
  - Perform SNAT (source NAT) so traffic exits via VPN
  - Redirect HTTP/HTTPS traffic to Burp Suite

## 📸 Screenshots

_Screenshots coming soon showing the GL.iNet admin panel configuration._

## ⚙️ Requirements

- `ethtool`
- Root privileges
- Active VPN on `tun0`
- Burp Suite running on port `8080`
- GL.iNet router connected to `eth1`
- Victim device IP: `192.168.10.200`

## 📄 Usage

```bash
┌──(kali㉿kali)-[~/tools]
└─$ sudo ./mobile-GLiNET.sh
```