{
  config,
  pkgs,
  lib,
  ...
}:

let
  # The subnet we will use for the VPN
  vpnSubnet = "10.100.0";
  vpnPort = 51820;

  # The helper script to manage WireGuard dynamically
  vpnScript = pkgs.writeShellScriptBin "vpn" ''
    set -e
    
    WG_DIR="/etc/wireguard"
    CONF_FILE="$WG_DIR/wg0.conf"
    SUBNET="${vpnSubnet}"
    PORT="${toString vpnPort}"
    
    # Ensure root
    if [ "$EUID" -ne 0 ]; then
      echo "Please run as root (sudo vpn ...)"
      exit 1
    fi

    mkdir -p $WG_DIR
    chmod 700 $WG_DIR

    function get_next_ip() {
        # Simple logic: find the highest used IP in the subnet and add 1.
        # Defaults to .2 if no peers found.
        local last_ip=$(grep -oP "AllowedIPs = $SUBNET.\K\d+" $CONF_FILE | sort -n | tail -1)
        if [ -z "$last_ip" ]; then
            echo "2"
        else
            echo $((last_ip + 1))
        fi
    }

    function cmd_init() {
        if [ -f "$CONF_FILE" ]; then
            echo "Config already exists at $CONF_FILE"
            return
        fi
        
        echo "Initializing WireGuard server..."
        umask 077
        wg genkey | tee $WG_DIR/private.key | wg pubkey > $WG_DIR/public.key
        
        PRIVATE_KEY=$(cat $WG_DIR/private.key)
        
        # Determine external interface for iptables rules
        EXT_IF=$(ip route list default | awk '{print $5}' | head -n1)
        if [ -z "$EXT_IF" ]; then EXT_IF="eth0"; fi
        
        cat > $CONF_FILE <<EOF
[Interface]
Address = $SUBNET.1/24
ListenPort = $PORT
PrivateKey = $PRIVATE_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $EXT_IF -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $EXT_IF -j MASQUERADE
SaveConfig = false
EOF
        echo "Server configured. Public Key: $(cat $WG_DIR/public.key)"
        echo "External Interface detected: $EXT_IF"
    }

    function cmd_add() {
        CLIENT_NAME=$1
        if [ -z "$CLIENT_NAME" ]; then echo "Usage: vpn add <client_name>"; exit 1; fi
        
        if [ ! -f "$CONF_FILE" ]; then cmd_init; fi
        
        if grep -q "# Client: $CLIENT_NAME" "$CONF_FILE"; then
            echo "Error: Client '$CLIENT_NAME' already exists."
            exit 1
        fi
        
        # Generate Client Keys
        CLIENT_PRIV=$(wg genkey)
        CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
        CLIENT_PSK=$(wg genpsk)
        
        # Assign IP
        NEXT_IP=$(get_next_ip)
        CLIENT_IP="$SUBNET.$NEXT_IP"
        
        echo "Adding peer '$CLIENT_NAME' with IP $CLIENT_IP..."
        
        # Add to Server Config
        cat >> $CONF_FILE <<EOF

# Client: $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUB
PresharedKey = $CLIENT_PSK
AllowedIPs = $CLIENT_IP/32
EOF

        # Reload Server
        # We use wg syncconf to reload without disrupting other connections
        wg syncconf wg0 <(wg-quick strip wg0)
        
        # Generate Client Config
        SERVER_PUB=$(cat $WG_DIR/public.key)
        # Try to detect public IP
        PUBLIC_IP=$(curl -s ifconfig.me)
        
        echo ""
        echo "=== Client Config ($CLIENT_NAME) ==="
        echo "Scan this QR code with the WireGuard App:"
        echo ""
        
        CLIENT_CONF="[Interface]
PrivateKey = $CLIENT_PRIV
Address = $CLIENT_IP/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB
PresharedKey = $CLIENT_PSK
AllowedIPs = 0.0.0.0/0
Endpoint = $PUBLIC_IP:$PORT
PersistentKeepalive = 25
"
        echo "$CLIENT_CONF" | qrencode -t ansiutf8
        
        echo ""
        echo "=== Raw Config ==="
        echo "$CLIENT_CONF"
        echo ""
    }

    function cmd_list() {
        if [ ! -f "$CONF_FILE" ]; then
            echo "No config found."
            exit 1
        fi
        
        echo "=== Registered Clients ==="
        grep -n "# Client:" "$CONF_FILE" | cut -d: -f3 | tr -d ' '
        
        echo ""
        echo "=== Active Connections ==="
        wg show wg0 endpoints
    }

    function cmd_remove() {
        CLIENT_NAME=$1
        if [ -z "$CLIENT_NAME" ]; then echo "Usage: vpn remove <client_name>"; exit 1; fi
        
        if [ ! -f "$CONF_FILE" ]; then
            echo "No config found."
            exit 1
        fi
        
        if ! grep -q "# Client: $CLIENT_NAME" "$CONF_FILE"; then
            echo "Error: Client '$CLIENT_NAME' not found."
            exit 1
        fi
        
        echo "Removing client '$CLIENT_NAME'..."
        
        # Create a temp file
        TMP_FILE=$(mktemp)
        
        # Use awk to filter out the block
        # It skips lines starting from "# Client: NAME" until the next empty line
        awk -v client="$CLIENT_NAME" '
            BEGIN { skip = 0 }
            /^# Client:/ { 
                if ($0 ~ client) { skip = 1 } 
                else { skip = 0 }
            }
            { 
                if (skip == 1 && /^$/) { skip = 0; next } 
                if (skip == 0) print $0 
            }
        ' "$CONF_FILE" > "$TMP_FILE"
        
        # Move back
        mv "$TMP_FILE" "$CONF_FILE"
        chmod 600 "$CONF_FILE"
        
        # Reload
        wg syncconf wg0 <(wg-quick strip wg0)
        echo "Client removed and configuration reloaded."
    }

    case "$1" in
        init) cmd_init ;;
        add) cmd_add "$2" ;;
        list) cmd_list ;;
        remove) cmd_remove "$2" ;;
        *) echo "Usage: vpn {init|add <name>|list|remove <name>}" ;;
    esac
  '';

in
{
  environment.systemPackages = [
    pkgs.wireguard-tools
    pkgs.qrencode
    pkgs.iptables
    vpnScript
  ];

  # Enable NAT and Kernel Forwarding
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nat = {
    enable = true;
    externalInterface = "eno2"; # Ensure this matches your real interface
    internalInterfaces = [ "wg0" ];
  };

  networking.firewall = {
    allowedUDPPorts = [ vpnPort ];
  };

  # Custom systemd service to manage the interface from the mutable config
  systemd.services.wg-quick-wg0 = {
    description = "WireGuard Server (Mutable)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [
      pkgs.wireguard-tools
      pkgs.iptables
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # We just use wg-quick directly on the mutable file
      ExecStart = "${pkgs.wireguard-tools}/bin/wg-quick up /etc/wireguard/wg0.conf";
      ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down /etc/wireguard/wg0.conf";
      Restart = "on-failure";
    };
  };
}
