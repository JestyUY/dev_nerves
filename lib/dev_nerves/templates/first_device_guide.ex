defmodule DevNerves.Templates.FirstDeviceGuide do
  @moduledoc """
  Generates the FIRST_DEVICE.md guide for getting started with Nerves.
  """

  def write(project_path, config) do
    content = template(project_path, config)
    File.write!(Path.join(project_path, "FIRST_DEVICE.md"), content)
  end

  defp template(project_path, config) do
    project_name = Path.basename(project_path)

    """
    # 🚀 Your First Nerves Device - Complete Guide

    Welcome to Nerves development! This guide will walk you through setting up and deploying your first Nerves firmware using the dev container environment.

    ## 📋 Prerequisites

    Before you start, make sure you have:

    - ✅ **Docker Desktop** installed and running
    - ✅ **VS Code** with the "Dev Containers" extension installed
    - ✅ **An SD card** (8GB or larger recommended)
    - ✅ **Your target device**: #{format_device_name(config.target)}
    - ✅ **Power supply** for your device (check device requirements)

    ⚠️ **Important:** You do NOT need Elixir, Erlang, or Nerves installed on your host machine!
    Everything runs inside the Docker dev container.

    ### 🪟 Windows Users - Important Setup

    ⚠️ **Enable Host Networking in Docker Desktop:**

    1. Open **Docker Desktop**
    2. Go to **Settings** ⚙️
    3. Navigate to **Resources → Network**
    4. Check ✅ **"Enable host networking"**
    5. Click **"Apply & Restart"**

    This is required for the dev container to communicate with your Nerves device on the local network.

    ---

    ## 🐳 Step 1: Open in Dev Container

    1. **Open this project folder in VS Code**
       ```
       cd #{project_name}
       code #{project_name}.code-workspace
       ```

    2. **Reopen in Container**
       - Press `F1` (or `Ctrl+Shift+P`)
       - Type and select: **"Dev Containers: Reopen in Container"**
       - Wait for the container to build (first time takes 5-10 minutes)

    3. **Verify Container is Running**
       - Look for "Dev Container: Nerves Dev Container" in the bottom-left corner of VS Code
       - Open a terminal in VS Code (`Ctrl+\``)

    ---

    ## 🔑 Step 2: Generate SSH Keys (First Time Only)

    SSH keys are used to securely connect to your Nerves device.

    **In the dev container terminal:**

    ```bash
    # Generate an ED25519 SSH key (recommended)
    ssh-keygen -t ed25519 -f ~/.ssh/nerves_key -N ""

    # Or generate an RSA key (if ED25519 is not supported)
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/nerves_key -N ""
    ```

    Your SSH keys will be stored in the `.ssh` directory and automatically mounted in the container.

    **View your public key:**
    ```bash
    cat ~/.ssh/nerves_key.pub
    ```

    ---

    ## 📦 Step 3: Install Dependencies and Build Firmware

    ⚠️ **IMPORTANT: All these commands run INSIDE the dev container, NOT on your host machine!**

    **In the dev container terminal:**

    ```bash
    # Navigate to your project (should already be there)
    cd /workspaces/#{project_name}

    # Verify the target is set
    echo $MIX_TARGET
    # Should output: #{config.target}

    # Install dependencies (FIRST TIME - this happens in the container)
    mix deps.get

    # Build the firmware (this takes 5-15 minutes the first time)
    # All compilation happens in the container with proper toolchain
    mix firmware
    ```

    **Why use the dev container?**
    - ✅ No need to install Elixir/Erlang/Nerves on Windows
    - ✅ Consistent build environment for all developers
    - ✅ All required build tools pre-installed
    - ✅ Works the same on Windows/Mac/Linux

    **What happens during the build?**
    - Downloads the Nerves system for your target device
    - Compiles your Elixir application
    - Builds the Linux kernel and root filesystem
    - Creates a firmware file (.fw)

    The firmware will be located at:
    ```
    _build/#{config.target}_dev/nerves/images/#{project_name}.fw
    ```

    #{wifi_configuration_section(config)}

    ---

    ## 💾 Step 4: Burn Firmware to SD Card

    Choose the method that works best for your operating system:

    ### Option A: Balena Etcher (Recommended for Windows)

    **✨ Best for beginners - Simple GUI interface**

    1. **Download Balena Etcher**
       - Visit: https://www.balena.io/etcher/
       - Install on your **Windows host machine** (not in the container)

    2. **Create a disk image** (in the dev container):
       ```bash
       mix firmware.image firmware.img
       ```

    3. **Flash the SD card** (on your Windows host):
       - Open Balena Etcher
       - Click **"Flash from file"** → Select `firmware.img`
       - Click **"Select target"** → Choose your SD card
       - Click **"Flash!"**
       - Wait for verification to complete

    ### Option B: Using fwup (Linux/Mac)

    **For Linux or Mac users with direct SD card access**

    ```bash
    # Find your SD card device
    # Linux:
    lsblk
    # Mac:
    diskutil list

    # Burn firmware (replace /dev/sdX with your device!)
    # WARNING: Double-check the device name to avoid data loss!
    sudo fwup _build/#{config.target}_dev/nerves/images/#{project_name}.fw -d /dev/sdX

    # Or use the mix task:
    mix burn
    # Follow the prompts to select the correct device
    ```

    ### Option C: Using WSL2 (Windows Subsystem for Linux)

    **If you have WSL2 with usbipd configured**

    ```bash
    # In PowerShell (as Administrator), attach USB device to WSL
    usbipd wsl attach --busid <busid>

    # In WSL terminal
    sudo fwup /mnt/c/path/to/firmware.fw -d /dev/sdX
    ```

    ⚠️ **IMPORTANT:** Always double-check the device name before burning! Using the wrong device can erase important data.

    ---

    ## ⚡ Step 5: Boot Your Device

    1. **Safely eject** the SD card from your computer
    2. **Insert** the SD card into your #{format_device_name(config.target)}
    3. **Connect power** to the device
       #{power_requirements(config.target)}
    4. **Wait 30-60 seconds** for the initial boot
    5. **Look for LED activity** to confirm the device is booting

    ### Boot Indicators

    - **Raspberry Pi**: Green LED flashes rapidly during boot
    - **BeagleBone Black**: LEDs light up in sequence
    - After boot completes, the device should be on the network

    ---

    ## 🔍 Step 6: Find Your Device on the Network

    ### Method 1: Using mDNS (Easiest)

    **From your host machine (Windows/Mac/Linux):**

    ```bash
    # Ping the device using its hostname
    ping nerves.local

    # If that works, your device is reachable at: nerves.local
    ```

    **Note:** mDNS (Bonjour) should work automatically on:
    - Mac OS X
    - Linux with Avahi installed
    - Windows 10+ (built-in support)

    ### Method 2: Network Scanning

    **From the dev container terminal:**

    ```bash
    # Scan your network for Nerves devices
    nmap -sn 192.168.1.0/24 | grep -B 2 nerves

    # Or more detailed scan:
    nmap -sL 192.168.1.1-254 | grep nerves

    # Find all devices on your network:
    nmap -sP 192.168.1.0/24
    ```

    Replace `192.168.1.0/24` with your network's subnet (check your router settings).

    ### Method 3: Check Router DHCP Leases

    1. Log into your **router's admin panel** (usually 192.168.1.1 or 192.168.0.1)
    2. Look for **DHCP clients** or **connected devices**
    3. Find a device named **"nerves"** or with hostname **"nerves"**
    4. Note its IP address

    ### Method 4: Serial Console (If All Else Fails)

    Connect via USB serial cable (specific to each board):
    - **Raspberry Pi**: USB-to-Serial adapter on GPIO pins
    - **BeagleBone Black**: Built-in USB serial (shows as /dev/ttyUSB0)

    ```bash
    # Find the serial device
    ls /dev/tty*

    # Connect using screen
    screen /dev/ttyUSB0 115200

    # Or using picocom
    picocom -b 115200 /dev/ttyUSB0
    ```

    ---

    ## 🌐 Step 7: SSH into Your Device

    Once you've found your device's address:

    ```bash
    # Using mDNS hostname (easiest)
    ssh nerves.local

    # Or using IP address
    ssh 192.168.1.XXX

    # With custom key
    ssh -i ~/.ssh/nerves_key nerves.local
    ```

    **Default credentials:**
    - Username: *(none required)*
    - Password: *(none required)*

    You'll be greeted with an IEx (Interactive Elixir) prompt:

    ```elixir
    Interactive Elixir (#{System.version()}) - press Ctrl+C to exit
    iex(nerves@nerves.local)1>
    ```

    ### Useful IEx Commands

    ```elixir
    # Attach the logger to see system logs
    RingLogger.attach()

    # Get system information
    Nerves.Runtime.log()

    # Check network configuration
    VintageNet.info()

    # See all network interfaces
    VintageNet.all_interfaces()

    # Reboot the device
    Nerves.Runtime.reboot()

    # Power off
    Nerves.Runtime.poweroff()

    # Exit SSH session
    exit()  # or press Ctrl+D twice
    ```

    ---

    ## 🚀 Step 8: Deploy Updates Over the Air (OTA)

    After making changes to your code, you can deploy updates wirelessly!

    **In the dev container:**

    ```bash
    # Build new firmware
    mix firmware

    # Upload to device (replaces firmware and reboots)
    mix upload nerves.local

    # Or upload to specific IP
    mix upload 192.168.1.XXX

    # Build and upload in one command
    mix firmware && mix upload nerves.local
    ```

    **What happens during upload:**
    1. New firmware is uploaded to the inactive partition
    2. Device is marked to boot from the new partition
    3. Device automatically reboots
    4. If new firmware fails, device rolls back to previous version

    **Monitor the update:**
    ```bash
    # In another terminal, watch the logs
    ssh nerves.local

    # In IEx, attach logger
    RingLogger.attach()
    ```

    ---

    ## 🐛 Troubleshooting

    ### Device Won't Boot

    **Symptoms:** No LED activity, device doesn't appear on network

    **Solutions:**
    - ✅ Verify the firmware was written correctly to the SD card
    - ✅ Check power supply (Raspberry Pi needs quality 5V/2.5A+ adapter)
    - ✅ Try a different SD card (some cards are not compatible)
    - ✅ Re-burn the firmware using a different method
    - ✅ Check the SD card contacts are clean

    ### Can't Find Device on Network

    **Symptoms:** `ping nerves.local` fails, can't find device

    **Solutions:**
    - ✅ Wait longer (first boot can take up to 2 minutes)
    - ✅ Check WiFi credentials in `config/target.exs`#{wifi_troubleshooting(config)}
    - ✅ Try connecting via Ethernet if available
    - ✅ Use serial console to debug boot process
    - ✅ Check router's DHCP leases manually
    - ✅ Verify your computer and device are on the same network
    - ✅ Disable VPN if running

    ### Build Failures

    **Symptoms:** `mix firmware` fails with errors

    **Solutions:**
    - ✅ **MOST COMMON:** Ensure you're in the dev container (check bottom-left corner)
    - ✅ **DO NOT** run `mix firmware` on your Windows host - it won't work!
    - ✅ Verify MIX_TARGET is set: `echo $MIX_TARGET`
    - ✅ Clean and rebuild (inside container):
      ```bash
      mix deps.clean --all
      mix deps.get
      mix firmware
      ```
    - ✅ Check internet connection (first build downloads ~500MB)
    - ✅ Ensure Docker has enough disk space (at least 10GB free)
    - ✅ Try rebuilding the dev container: F1 → "Dev Containers: Rebuild Container"

    ### Upload Failures

    **Symptoms:** `mix upload` fails or times out

    **Solutions:**
    - ✅ Verify device is reachable: `ping nerves.local`
    - ✅ Check SSH connection works: `ssh nerves.local`
    - ✅ Ensure device has enough space (check with `df -h` in IEx)
    - ✅ Try uploading by IP address instead of hostname
    - ✅ Check firewall settings on host machine
    - ✅ Verify host networking is enabled in Docker (Windows)

    ### WiFi Not Connecting

    **Symptoms:** Device boots but not on WiFi network

    **Solutions:**
    - ✅ Double-check SSID and password in configuration
    - ✅ Ensure WiFi is 2.4GHz (many devices don't support 5GHz)
    - ✅ Check WiFi encryption type (WPA2 is most common)
    - ✅ Try a mobile hotspot for testing
    - ✅ Use serial console to view WiFi connection logs

    ### SSH Connection Refused

    **Symptoms:** `ssh nerves.local` fails with "Connection refused"

    **Solutions:**
    - ✅ Device might still be booting (wait 30 more seconds)
    - ✅ Firmware might not include SSH (check configuration)
    - ✅ Try without specifying a key: `ssh nerves.local`
    - ✅ Verify SSH keys are properly configured

    ---

    ## 📚 Next Steps

    Congratulations! You have a working Nerves device. Here's what to explore next:

    ### Learn More

    - 📖 [Official Nerves Documentation](https://hexdocs.pm/nerves/getting-started.html)
    - 🎓 [Nerves Getting Started Guide](https://hexdocs.pm/nerves/getting-started.html)
    - 💬 [Elixir Forum - Nerves Category](https://elixirforum.com/c/nerves-forum)
    - 💬 [Elixir Slack](https://elixir-slack.community/) - Join #nerves channel

    ### Explore Examples

    - 🔬 [Nerves Examples Repository](https://github.com/nerves-project/nerves_examples)
    - 🎮 [Nerves Livebook](https://github.com/nerves-project/nerves_livebook)
    - 🌐 [Phoenix on Nerves](https://github.com/nerves-project/nerves_examples/tree/main/hello_phoenix)

    ### Add Hardware

    - 🔌 GPIO pins for LEDs, buttons, sensors
    - 📷 Camera modules
    - 🌡️ Temperature and humidity sensors
    - 🔊 Audio output/input
    - 📡 Additional wireless modules

    ### Customize Your System

    - 🎨 Create custom Nerves systems
    - 📦 Add additional Linux packages
    - ⚙️ Configure kernel modules
    - 🔧 Customize boot process

    ---

    ## 🛠️ Useful Commands Reference

    ### Firmware Management

    ```bash
    # Get firmware information
    mix firmware.info

    # Create a disk image
    mix firmware.image output.img

    # Burn to SD card interactively
    mix burn

    # Create firmware bundle for OTA updates
    mix firmware.gen.script
    ```

    ### Development Workflow

    ```bash
    # Clean build artifacts
    mix clean

    # Deep clean (removes everything)
    mix deps.clean --all && rm -rf _build

    # Run tests
    mix test

    # Format code
    mix format

    # Check for issues
    mix compile --warnings-as-errors
    ```

    ### Device Interaction

    ```bash
    # SSH into device
    ssh nerves.local

    # Run a command on the device
    ssh nerves.local -c "some_command"

    # Copy files to device
    scp file.txt nerves.local:/tmp/

    # Tail logs in real-time
    ssh nerves.local
    # Then in IEx:
    RingLogger.attach()
    ```

    ### Docker/Container Management

    ```bash
    # Rebuild dev container (from VS Code)
    # F1 → "Dev Containers: Rebuild Container"

    # Or from command line:
    docker-compose -f .devcontainer/docker-compose.yml build --no-cache
    ```

    ---

    ## 🎯 Project Configuration

    Your project is configured with:

    - **Target Device:** #{format_device_name(config.target)}
    - **Mix Target:** `#{config.target}`
    #{wifi_config_summary(config)}

    To change these settings, edit `.devcontainer/devcontainer.json` and rebuild the container.

    ---

    ## 💡 Tips and Best Practices

    1. **Always work in the dev container** - Never run `mix firmware` on Windows host
    2. **Always test on device** - Nerves runs differently than `mix test` on your host
    3. **Use RingLogger** - It saves logs in memory, viewable even after disconnection
    4. **Enable partition A/B** - Automatic rollback if new firmware fails
    5. **Monitor resource usage** - Embedded devices have limited RAM/storage
    6. **Use VintageNet** - For robust network configuration
    7. **Implement OTA carefully** - Always test firmware before deploying
    8. **Keep backups** - Save working firmware files
    9. **Document hardware connections** - GPIO pin mappings, etc.

    ---

    ## 🆘 Getting Help

    If you run into issues:

    1. **Check the logs** - `RingLogger.attach()` shows what's happening
    2. **Search the forum** - Someone likely had the same issue
    3. **Ask in Slack** - The #nerves channel is very helpful
    4. **Check GitHub issues** - Known issues and workarounds
    5. **Read the docs** - Comprehensive documentation at hexdocs.pm

    ---

    ## 🎉 You're Ready!

    You now have everything you need to build amazing IoT projects with Nerves!

    Happy hacking! 🚀🎯✨

    ---

    *Generated by dev_nerves on #{Date.utc_today()}*
    """
  end

  defp format_device_name("rpi0"), do: "Raspberry Pi Zero / Zero W"
  defp format_device_name("rpi3"), do: "Raspberry Pi 3 Model B/B+"
  defp format_device_name("rpi4"), do: "Raspberry Pi 4 Model B"
  defp format_device_name("rpi5"), do: "Raspberry Pi 5"
  defp format_device_name("bbb"), do: "BeagleBone Black"
  defp format_device_name(target), do: String.upcase(target)

  defp power_requirements("rpi0"), do: "- Minimum: 5V/1A (recommend 5V/2A)\n"
  defp power_requirements("rpi3"), do: "- Minimum: 5V/2.5A (recommend 5V/3A)\n"
  defp power_requirements("rpi4"), do: "- Minimum: 5V/3A (USB-C power supply)\n"
  defp power_requirements("rpi5"), do: "- Minimum: 5V/5A (USB-C power supply with PD)\n"
  defp power_requirements("bbb"), do: "- Minimum: 5V/2A (barrel jack or USB)\n"
  defp power_requirements(_), do: "- Check your device's power requirements\n"

  defp wifi_configuration_section(%{wifi_ssid: ssid, wifi_psk: _psk}) when ssid != "" do
    """
    ---

    ## 📡 WiFi Configuration

    Your WiFi is **already configured** via the dev container environment variables:

    - **SSID:** `#{ssid}`
    - **Status:** ✅ Configured

    The device should automatically connect to this network on boot.

    ### Change WiFi Settings

    If you need to change WiFi credentials:

    1. **Edit** `.devcontainer/devcontainer.json`
    2. **Update** the `WIFI_SSID` and `WIFI_PSK` environment variables
    3. **Rebuild** the dev container:
       - Press `F1` → "Dev Containers: Rebuild Container"
    4. **Rebuild firmware:** `mix firmware`
    5. **Update device:** `mix upload nerves.local`

    ### Alternative: Configure in target.exs

    You can also configure WiFi directly in `config/target.exs`:

    ```elixir
    config :vintage_net,
      regulatory_domain: "US",
      config: [
        {"wlan0",
         %{
           type: VintageNetWiFi,
           vintage_net_wifi: %{
             networks: [
               %{
                 key_mgmt: :wpa_psk,
                 ssid: System.get_env("WIFI_SSID"),
                 psk: System.get_env("WIFI_PSK")
               }
             ]
           },
           ipv4: %{method: :dhcp}
         }}
      ]
    ```
    """
  end

  defp wifi_configuration_section(_) do
    """
    ---

    ## 📡 WiFi Configuration (Required for Wireless Access)

    Your device needs WiFi configuration to connect wirelessly.

    ### Configure WiFi in target.exs

    **Edit** `config/target.exs` and add:

    ```elixir
    # Configure WiFi
    config :vintage_net,
      regulatory_domain: "US",
      config: [
        {"wlan0",
         %{
           type: VintageNetWiFi,
           vintage_net_wifi: %{
             networks: [
               %{
                 key_mgmt: :wpa_psk,
                 ssid: "YOUR_WIFI_SSID",
                 psk: "YOUR_WIFI_PASSWORD"
               }
             ]
           },
           ipv4: %{method: :dhcp}
         }},
        {"eth0",
         %{
           type: VintageNetEthernet,
           ipv4: %{method: :dhcp}
         }}
      ]
    ```

    **Replace:**
    - `YOUR_WIFI_SSID` with your WiFi network name
    - `YOUR_WIFI_PASSWORD` with your WiFi password

    ### After Configuration

    1. **Save** the file
    2. **Rebuild** firmware: `mix firmware`
    3. **Burn** to SD card or upload: `mix upload nerves.local`

    ### Multiple Networks

    You can configure multiple WiFi networks (device will connect to strongest signal):

    ```elixir
    networks: [
      %{
        key_mgmt: :wpa_psk,
        ssid: "Home_WiFi",
        psk: "home_password"
      },
      %{
        key_mgmt: :wpa_psk,
        ssid: "Work_WiFi",
        psk: "work_password"
      }
    ]
    ```

    ### WiFi Troubleshooting

    - ⚠️ Many devices only support **2.4GHz** WiFi (not 5GHz)
    - ⚠️ WPA2 is most compatible, WPA3 may not work
    - ⚠️ Hidden SSIs may require additional configuration
    """
  end

  defp wifi_troubleshooting(%{wifi_ssid: ssid}) when ssid != "" do
    """

    - ✅ Your WiFi is configured for SSID: **#{ssid}**
    - ✅ Verify password is correct in `.devcontainer/devcontainer.json`
    """
  end

  defp wifi_troubleshooting(_) do
    """

    - ✅ Configure WiFi in `config/target.exs`
    - ✅ Ensure SSID and password are correct
    """
  end

  defp wifi_config_summary(%{wifi_ssid: ssid}) when ssid != "" do
    "- **WiFi SSID:** `#{ssid}` (configured via environment)"
  end

  defp wifi_config_summary(_) do
    "- **WiFi:** Not configured (configure in `config/target.exs`)"
  end
end
