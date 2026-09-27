{ config, pkgs, lib, ... }:

let
  hostMac = "40:C7:3C:2F:8D:6F";
  deviceMac = "FE:C5:9D:FC:98:83";
  bluetoothDir = "/var/lib/bluetooth/${hostMac}/${deviceMac}";

  bluezInfoContent = ''
[General]
Name=Surface Pro Flex Keyboard
Appearance=0x03c1
AddressType=static
SupportedTechnologies=LE;
Trusted=true
Blocked=false
Services=00001800-0000-1000-8000-00805f9b34fb;00001801-0000-1000-8000-00805f9b34fb;0000180a-0000-1000-8000-00805f9b34fb;0000180f-0000-1000-8000-00805f9b34fb;00001812-0000-1000-8000-00805f9b34fb;

[IdentityResolvingKey]
Key=431BAC54CCE2EA1AEFB235BE3144CA8B

[LongTermKey]
Key=47972653016AF21CF7C38A192E3A4930
Authenticated=1
EncSize=16
EDiv=62649
Rand=5837191137475359221

[LocalSignatureKey]
Key=6D49B52312B30EB0757454839C97E40D
Counter=0
Authenticated=false
'';
in
{
  # Enable Bluetooth with Modern BLE & Battery Reporting Support
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true; # Exposes battery percentage to Waybar / UPower
        FastConnectable = true;
        Privacy = "off"; # MUST be off so adapter presents its static 40:C7:3C:2F:8D:6F MAC
        JustWorksRepairing = "always";
        Class = "0x000100";
      };
      Policy = {
        AutoEnable = true;
      };
    };
    input = {
      General = {
        UserspaceHID = true;
      };
    };
  };

  # Always ensure Bluetooth is unblocked on boot
  systemd.services.bluetooth.serviceConfig.ExecStartPre = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";

  # Declaratively inject keys into BlueZ unconditionally
  system.activationScripts.surfaceFlexBluetoothKeys = {
    text = ''
      mkdir -p /var/lib/bluetooth
      chmod 700 /var/lib/bluetooth
      mkdir -p "${bluetoothDir}"
      chmod 700 "/var/lib/bluetooth/${hostMac}" "${bluetoothDir}"

      echo "Injecting Surface Pro Flex Keyboard pre-shared LTK keys..."
      cat > "${bluetoothDir}/info" << 'EOF'
${bluezInfoContent}
EOF
      chmod 600 "${bluetoothDir}/info"

      # Also sync keys to any other active controller MAC directories
      for adp in /var/lib/bluetooth/*/; do
        if [ -d "$adp" ] && [ "$(basename "$adp")" != "${deviceMac}" ]; then
          mkdir -p "$adp/${deviceMac}"
          chmod 700 "$adp" "$adp/${deviceMac}"
          cat > "$adp/${deviceMac}/info" << 'EOF'
${bluezInfoContent}
EOF
          chmod 600 "$adp/${deviceMac}/info"
        fi
      done

      chown -R root:root /var/lib/bluetooth
    '';
  };
}
