{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    # Surface Pro Intel hardware profile from nixos-hardware (linux-surface kernel + SAM)
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
  ];

  # Intel Core Ultra 5 135U Platform Microcode & Firmware
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Intel Arc Xe-LPG Graphics & Hardware Video Acceleration (VA-API / QSV)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver     # Hardware VA-API (H.264, HEVC, AV1)
      vpl-gpu-rt             # Intel Video Processing Library
      intel-compute-runtime  # OpenCL compute engine
    ];
  };

  # Intel AI Boost NPU (NPU 3720) Driver
  hardware.cpu.intel.npu.enable = true;

  # IPTS Daemon (Intel Precise Touch & Stylus)
  # Translates raw digitizer data into standard Linux multi-touch & pen evdev events
  services.iptsd = {
    enable = true;
    config = {
      Touchscreen = {
        DisableOnPalm = true;
      };
      Stylus = {
        Disable = false;
      };
    };
  };

  # Surface Accelerometer / Gyroscope / Ambient Light Sensor
  hardware.sensor.iio.enable = true;

  # Power Management & S0ix Modern Standby
  powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [
    "uhid"
    "surface_aggregator"
    "surface_aggregator_registry"
    "surface_hid"
    "surface_kbd"
    "intel_vpu"
  ];

  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
  '';


  boot.kernelParams = [
    # S0ix Modern Standby
    "mem_sleep_default=s2idle"

    # Disable Panel Self Refresh (PSR/PSR2) - known cause of Intel display/GPU lockup & reset on sleep
    "i915.enable_psr=0"
    "xe.enable_psr=0"

    # Disable Intel TCO hardware watchdog to prevent unlogged hard resets during S0ix transitions
    "nowatchdog"
    "modprobe.blacklist=iTCO_wdt,iTCO_vendor_support"

    "pci=pcie_bus_perf"
  ];

  # S0ix Power Management: Use "freeze" (s2idle). NEVER use "mem" (S3 is unsupported on Surface Pro 10)
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "yes";
    AllowHibernation = "yes";
    SuspendState = "freeze";
    HibernateDelaySec = "1800";
  };
  environment.systemPackages = with pkgs; [
    surface-control
    intel-npu-driver
    brightnessctl
    libinput
    clinfo
    vulkan-tools
  ];
}
