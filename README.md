# aws-proxy

Minimal Terraform setup for a single Lightsail instance running `Xray` with a `VLESS + REALITY` inbound on port `443`.

## What This Creates

- 1 AWS Lightsail instance in `ap-northeast-1a`
- 1 static IPv4 address attached to the instance
- Firewall rule allowing inbound TCP `443`
- Xray installed through instance `user_data`
- Xray configured with a single `VLESS + REALITY` listener

## Requirements

- Terraform `>= 1.0`
- AWS credentials configured locally with permission to manage Lightsail resources
- An AWS region with Lightsail support

## Files

- `main.tf`: infrastructure and bootstrap script
- `terraform.tfvars.example`: example input values
- `refresh_ip.sh`: helper to rotate the public IPs after deployment

## Configure Variables

Copy the example file and fill in your own values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Required variables:

- `xray_uuid`: client UUID used by the VLESS inbound
- `xray_private_key`: REALITY private key used by the server
- `xray_short_id`: short ID used by authorized clients
- `dest_domain`: hostname used by the REALITY configuration

Example:

```hcl
xray_uuid        = "00000000-0000-0000-0000-000000000000"
xray_private_key = "REPLACE_WITH_REALITY_PRIVATE_KEY"
xray_short_id    = "0123456789abcdef"
dest_domain      = "example.com"
```

## Generate Xray Values

If you already have `xray` installed locally, you can generate a UUID and an X25519 keypair with:

```bash
xray uuid
xray x25519
```

Use the generated private key as `xray_private_key`.
Use the generated public key in your client configuration.

For `xray_short_id`, use a short hexadecimal string, for example `0123456789abcdef`.

## Deploy

Initialize and apply:

```bash
terraform init
terraform apply
```

After the apply completes, Terraform prints the server IP as the `server_ip` output.

You can also retrieve it later with:

```bash
terraform output server_ip
```

## Client Setup

Your client needs the following values:

- Address: the deployed server IP
- Port: `443`
- Protocol: `VLESS`
- Transport: `TCP`
- Security: `REALITY`
- UUID: `xray_uuid`
- Public key: public key paired with `xray_private_key`
- Short ID: `xray_short_id`
- Server name: `dest_domain`
- Flow: `xtls-rprx-vision`

## Client Software

Common clients:

- Android: `v2rayNG` - <https://github.com/2dust/v2rayNG>
- Windows: `v2rayN` - <https://github.com/2dust/v2rayN>
- Cross-platform GUI: `Nekoray` - <https://github.com/MatsuriDayo/nekoray>
- Core project and docs: `Xray-core` - <https://github.com/XTLS/Xray-core>

Check each client's current support for `REALITY` before use.

## Rotate the Public IP

This repo includes a helper script for rotating the public IPs:

```bash
chmod +x refresh_ip.sh
./refresh_ip.sh
```

The script expects:

- the instance name to remain `vless-reality-server`
- the static IP name to remain `vless-static-ip`
- the region to remain `ap-northeast-1`
- the AWS CLI to be installed and authenticated locally

If you change those values in Terraform, update `refresh_ip.sh` to match.

## Notes

- `terraform.tfvars`, `*.tfstate`, `.terraform/`, and local client config files are ignored by `.gitignore` and should not be committed.
- `main.tf` currently hardcodes the Lightsail AZ, instance name, and region-specific assumptions. If you want a more reusable module, parameterize those values before publishing widely.
