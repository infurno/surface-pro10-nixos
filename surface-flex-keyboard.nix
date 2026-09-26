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
        Privacy = "device";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Declaratively inject keys into BlueZ before service startup
  system.activationScripts.surfaceFlexBluetoothKeys = {
    text = ''
      mkdir -p "${bluetoothDir}"
      chmod 700 /var/lib/bluetooth /var/lib/bluetooth/${hostMac} "${bluetoothDir}"

      if [ ! -f "${bluetoothDir}/info" ]; then
        echo "Injecting Surface Pro Flex Keyboard pre-shared LTK keys..."
        cat > "${bluetoothDir}/info" << 'EOF'
${bluezInfoContent}
EOF
        chmod 600 "${bluetoothDir}/info"
        chown -R root:root /var/lib/bluetooth
      fi
    '';
  };
}
