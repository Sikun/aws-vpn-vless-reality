variable "xray_uuid" {
  description = "Client UUID for the VLESS inbound."
}

variable "xray_private_key" {
  description = "REALITY private key used by the server."
  sensitive   = true
}

variable "xray_short_id" {
  description = "REALITY short ID presented by authorized clients."
}

variable "dest_domain" {
  description = "TLS destination hostname used by the REALITY configuration."
}

resource "aws_lightsail_instance" "vless_node" {
  name              = "vless-reality-server"
  availability_zone = "ap-northeast-1a"
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "small_3_0"

  user_data = <<-EOF
    #!/bin/bash
    apt-get update && apt-get install -y curl
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    cat <<EOT > /usr/local/etc/xray/config.json
    {
        "log": { "loglevel": "warning" },
        "dns": {
          "servers": [
            "https+local://1.1.1.1/dns-query",
            "https+local://[2606:4700:4700::1111]/dns-query",
            "localhost"
          ],
          "queryStrategy": "UseIP"
        },
        "inbounds": [{
            "listen": "::",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [{ "id": "${var.xray_uuid}", "flow": "xtls-rprx-vision" }],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "${var.dest_domain}:443",
                    "xver": 0,
                    "serverNames": ["${var.dest_domain}"],
                    "privateKey": "${var.xray_private_key}",
                    "shortIds": ["${var.xray_short_id}"]
                }
            }
        }],
        "outbounds": [
            {
                "protocol": "freedom",
                "settings": {
                    "domainStrategy": "UseIP" // Valid options: UseIP, UseIPv4, UseIPv6
                }
            },
            {
                "protocol": "blackhole",
                "tag": "block"
            }
        ],
        "routing": {
          "domainStrategy": "IPIfNonMatch",
          "rules": [
            {
              "type": "field",
              "ip": ["geoip:private"],
              "outboundTag": "block"
            }
          ]
        }
    }
    EOT
    systemctl restart xray
  EOF
}

resource "aws_lightsail_static_ip" "vless_ip" {
  name = "vless-static-ip"
}

resource "aws_lightsail_static_ip_attachment" "vless_attach" {
  static_ip_name = aws_lightsail_static_ip.vless_ip.name
  instance_name  = aws_lightsail_instance.vless_node.name
}

resource "aws_lightsail_instance_public_ports" "vless_firewall" {
  instance_name = aws_lightsail_instance.vless_node.name

  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidrs      = ["0.0.0.0/0"] 
    ipv6_cidrs = ["::/0"] # Explicitly allow IPv6
  }
}

output "server_ip" { value = aws_lightsail_static_ip.vless_ip.ip_address }
