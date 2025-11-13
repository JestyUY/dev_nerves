# DevNerves

A Mix task that creates Nerves projects with complete dev container setup, making Nerves development on Windows (and other platforms) smooth and hassle-free.



```mix archive.install hex dev_nerves```


```mix dev_nerves.new project_name```


## 🚀 Features

- **🐳 Dev Container** - Pre-configured Docker environment with all Nerves tools
- **🪟 Windows Friendly** - Specifically designed to solve Windows development pain points
- **🎯 Multiple Targets** - Support for Raspberry Pi (Zero, 3, 4, 5) and BeagleBone Black
- **📡 WiFi Setup** - Optional WiFi configuration during project creation
- **🔧 VS Code Integration** - Workspace file with proper ElixirLS configuration

## 📋 Prerequisites

Before installing DevNerves, ensure you have:

- **Elixir** 1.14 or later
- **Mix** (comes with Elixir)
- **Docker Desktop** installed and running
- **VS Code** with the "Dev Containers" extension

### Windows Users

Enable host networking in Docker Desktop:
1. Open Docker Desktop Settings
2. Go to Resources → Network
3. Check "Enable host networking"
4. Click "Apply & Restart"

## 📦 Installation

### Option 1: Install from Hex (Recommended)

```bash
mix archive.install hex dev_nerves
```

### Option 2: Install from Source

```bash
git clone https://github.com/yourusername/dev_nerves.git
cd dev_nerves
mix do deps.get, archive.build, archive.install
```

## 🎮 Usage

### Basic Usage

```bash
mix dev_nerves.new my_robot
```

This will:
1. Launch an interactive setup wizard
2. Ask you to select your target device
3. Optionally configure WiFi
4. Create a complete Nerves project with dev container setup

### Advanced Usage

Skip the interactive prompts by providing options:

```bash
# Create project with specific target
mix dev_nerves.new my_robot --target rpi4

# Create with WiFi pre-configured
mix dev_nerves.new my_robot --target rpi4 --wifi-ssid "MyWiFi" --wifi-psk "password123"

# Short form
mix dev_nerves.new my_robot -t rpi3
```

### Options

- `--target`, `-t` - Target device: `rpi0`, `rpi3`, `rpi4`, `rpi5`, `bbb`
- `--wifi-ssid` - WiFi network name (SSID)
- `--wifi-psk` - WiFi password

## 🎯 Supported Targets

DevNerves supports all officially supported Nerves targets:

| Device | Target Code | Description |
|--------|------------|-------------|
| Raspberry Pi A+, B, B+ | `rpi` | BCM2835, 512MB RAM |
| Raspberry Pi Zero/Zero W | `rpi0` | BCM2835, 512MB RAM |
| Raspberry Pi Zero 2W / 3A (64-bit) | `rpi0_2` | BCM2837, 512MB RAM |
| Raspberry Pi 2 Model B | `rpi2` | BCM2836, 1GB RAM |
| Raspberry Pi 3 Model B/B+ | `rpi3` | BCM2837, 1GB RAM |
| Raspberry Pi Zero 2W / 3A (32-bit) | `rpi3a` | BCM2837, 512MB RAM |
| Raspberry Pi 4 Model B | `rpi4` | BCM2711, 2-8GB RAM |
| Raspberry Pi 5 | `rpi5` | BCM2712, 4-8GB RAM |
| BeagleBone Black/Green/Wireless, PocketBeagle | `bbb` | AM335x, 512MB RAM |
| Generic x86_64 | `x86_64` | x86_64 architecture |
| OSD32MP1 | `osd32mp1` | STM32MP157, 512MB RAM |
| GRiSP 2 | `grisp2` | i.MX 6UL, 512MB RAM |
| MangoPi MQ Pro | `mangopi_mq_pro` | Allwinner D1, 1GB RAM |

See [Nerves Supported Targets](https://hexdocs.pm/nerves/supported-targets.html) for more details.

## 🛠️ What Gets Created

When you run `mix dev_nerves.new my_robot`, you get:

```
my_robot/
├── .devcontainer/
│   ├── devcontainer.json    # VS Code dev container config
│   ├── docker-compose.yml   # Docker Compose setup
│   └── Dockerfile           # Container with all Nerves tools
├── .ssh/
│   └── .gitkeep            # Mount point for SSH keys
├── config/                 # Nerves configuration
├── lib/                    # Your application code
├── test/                   # Tests
├── .gitignore             # Updated with dev container entries
├── FIRST_DEVICE.md        # Complete getting started guide
├── my_robot.code-workspace # VS Code workspace file
└── mix.exs                # Project configuration
```

## 🚀 Quick Start After Creation

After creating your project:

```bash
# 1. Open in VS Code
cd my_robot
code my_robot.code-workspace

# 2. Reopen in Container
# Press F1 → "Dev Containers: Reopen in Container"
# Wait for container to build (5-10 minutes first time)

# 3. Inside the container terminal:
mix deps.get
mix firmware

# 4. Burn to SD card (from host machine with Balena Etcher)
# Or use fwup on Linux/Mac

# 5. Boot your device and connect!
ssh nerves.local
```

For detailed instructions, see the auto-generated `FIRST_DEVICE.md` in your project!

## 📖 Documentation

Each created project includes a comprehensive `FIRST_DEVICE.md` guide covering:

- ✅ Prerequisites and setup
- ✅ Opening the dev container
- ✅ Generating SSH keys
- ✅ Building firmware
- ✅ Burning to SD card (multiple methods)
- ✅ Finding your device on the network
- ✅ SSH connection
- ✅ OTA updates
- ✅ Troubleshooting common issues
- ✅ Next steps and resources

## 🎨 Interactive UI with Owl

DevNerves uses the powerful [Owl library](https://hex.pm/packages/owl) by Mykola Konyk for beautiful CLI interactions:

- **Arrow key navigation** - Use ↑↓ keys to select options, no typing numbers!
- **Multi-select menus** - Beautiful, intuitive selection interface
- **Colored output** - Clear visual feedback with semantic colors
- **Secure password input** - WiFi passwords hidden while typing
- **Progress indicators** - Real-time feedback on what's happening

Owl makes the CLI experience feel modern and professional, similar to tools like `npm create` or `cargo new`.

### Example Interaction

```
╔═══════════════════════════════════════════════════╗
║  🚀 Nerves Dev Container Setup                   ║
║  Easy Nerves development for Windows users       ║
╚═══════════════════════════════════════════════════╝

📋 Configuration

Select your target device:

❯ Raspberry Pi 4 Model B - BCM2711, 2-8GB RAM
  Raspberry Pi 3 Model B/B+ - BCM2837, 1GB RAM
  Raspberry Pi Zero / Zero W - BCM2835, 512MB RAM
  Raspberry Pi 5 - BCM2712, 4-8GB RAM
  BeagleBone Black - AM335x, 512MB RAM

✓ Selected: rpi4
```

## 🐛 Troubleshooting

### "mix: command not found"

Install Elixir first: https://elixir-lang.org/install.html

### "nerves_bootstrap not found"

Install Nerves bootstrap:

```bash
mix archive.install hex nerves_bootstrap
```

### Docker Container Won't Start

- Ensure Docker Desktop is running
- Check that virtualization is enabled in BIOS (Windows)
- Try rebuilding: F1 → "Dev Containers: Rebuild Container"

### Can't Find Device on Network (Windows)

- Enable host networking in Docker Desktop settings
- Disable VPN temporarily
- Check firewall settings

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development

```bash
# Clone the repository
git clone https://github.com/yourusername/dev_nerves.git
cd dev_nerves

# Install dependencies
mix deps.get

# Run tests
mix test

# Build archive locally
mix archive.build

# Install locally for testing
mix archive.install
```

## 📚 Resources

- [Nerves Project](https://nerves-project.org/)
- [Nerves Documentation](https://hexdocs.pm/nerves/getting-started.html)
- [Elixir Lang](https://elixir-lang.org/)
- [Owl Library](https://hex.pm/packages/owl)
- [Original Dev Container Inspiration](https://github.com/Oooska/elixir_nerves_devcontainer)

## 📄 License

Apache License 2.0

## 🙏 Acknowledgments

- Inspired by [Oooska's Elixir Nerves DevContainer](https://github.com/Oooska/elixir_nerves_devcontainer)
- Built with the excellent [Owl](https://hex.pm/packages/owl) library by Mykola Konyk for beautiful CLI interactions

---

Made with ❤️ for the Elixir and Nerves community
