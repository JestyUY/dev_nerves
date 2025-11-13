defmodule Mix.Tasks.DevNerves.New do
  @moduledoc """
  Creates a new Nerves project with dev container setup for Windows users.

  ## Usage

      mix dev_nerves.new PROJECT_NAME [OPTIONS]

  ## Options

      --target, -t    Target device (rpi, rpi0, rpi0_2, rpi2, rpi3, rpi3a, rpi4, rpi5,
                      bbb, x86_64, osd32mp1, grisp2, mangopi_mq_pro)
      --wifi-ssid     WiFi SSID to configure
      --wifi-psk      WiFi password to configure

  ## Example

      mix dev_nerves.new my_robot
      mix dev_nerves.new my_robot --target rpi4 --wifi-ssid "MyWiFi" --wifi-psk "password123"

  This will:
  - Create a new Nerves project
  - Add dev container configuration
  - Set up Docker Compose and Dockerfile
  - Configure VS Code workspace
  - Generate a comprehensive getting started guide
  """

  use Mix.Task
  require Logger

  alias DevNerves.UI

  @shortdoc "Creates a new Nerves project with dev container setup"

  @switches [
    target: :string,
    wifi_ssid: :string,
    wifi_psk: :string
  ]

  @aliases [
    t: :target
  ]

  @targets [
    %{name: "Raspberry Pi A+, B, B+", value: "rpi", description: "BCM2835, 512MB RAM"},
    %{name: "Raspberry Pi Zero / Zero W", value: "rpi0", description: "BCM2835, 512MB RAM"},
    %{name: "Raspberry Pi 2", value: "rpi2", description: "BCM2836, 1GB RAM"},
    %{name: "Raspberry Pi 3A and Zero 2 W (32 bits)", value: "rpi3a", description: "BCM2837, 512MB RAM"},
    %{name: "Raspberry Pi 3A and Zero 2 W (64 bits)", value: "rpi0_2", description: "BCM2837, 512MB RAM"},
    %{name: "Raspberry Pi 3 B, B+", value: "rpi3", description: "BCM2837, 1GB RAM"},
    %{name: "Raspberry Pi 4", value: "rpi4", description: "BCM2711, 2-8GB RAM"},
    %{name: "Raspberry Pi 5", value: "rpi5", description: "BCM2712, 4-8GB RAM"},
    %{name: "BeagleBone Black/Green/Wireless, PocketBeagle", value: "bbb", description: "AM335x, 512MB RAM"},
    %{name: "Generic x86_64", value: "x86_64", description: "x86_64 architecture"},
    %{name: "OSD32MP1", value: "osd32mp1", description: "STM32MP157, 512MB RAM"},
    %{name: "GRiSP 2", value: "grisp2", description: "i.MX 6UL, 512MB RAM"},
    %{name: "MangoPi MQ Pro", value: "mangopi_mq_pro", description: "Allwinner D1, 1GB RAM"}
  ]

  def run(args) do
    Application.ensure_all_started(:owl)

    case OptionParser.parse(args, switches: @switches, aliases: @aliases) do
      {opts, [project_name], _} ->
        validate_project_name!(project_name)
        create_project(project_name, opts)

      {_, [], _} ->
        UI.puts([
          UI.tag("Error: ", :red),
          "Expected PROJECT_NAME to be given.\n",
          "Usage: mix dev_nerves.new PROJECT_NAME"
        ])
        exit({:shutdown, 1})

      {_, _projects, _} ->
        UI.puts([
          UI.tag("Error: ", :red),
          "Expected a single PROJECT_NAME, got multiple arguments."
        ])
        exit({:shutdown, 1})
    end
  end

  defp validate_project_name!(name) do
    cond do
      not valid_project_name?(name) ->
        UI.puts([
          UI.tag("Error: ", :red),
          "Invalid project name '#{name}'.\n",
          "Project name must start with a lowercase letter, followed by lowercase letters, numbers, or underscores."
        ])
        exit({:shutdown, 1})

      File.exists?(name) ->
        UI.puts([
          UI.tag("Error: ", :red),
          "Directory '#{name}' already exists."
        ])
        exit({:shutdown, 1})

      true ->
        :ok
    end
  end

  defp valid_project_name?(name) do
    String.match?(name, ~r/^[a-z][a-z0-9_]*$/)
  end

  defp create_project(project_name, opts) do
    show_banner()
    config = gather_configuration(opts)
    interactive_mode = is_nil(opts[:target])
    install_deps = if interactive_mode, do: prompt_install_deps(), else: false

    create_nerves_project(project_name, config, install_deps)

    add_devcontainer_setup(project_name, config)


    show_success_message(project_name, config)
  end

  defp show_banner do
    UI.puts([
      "\n",
      UI.tag("╔═══════════════════════════════════════════════════╗\n", :cyan),
      UI.tag("║  ", :cyan),
      UI.tag("🚀 Nerves Dev Container Setup", :bright),
      UI.tag("║\n", :cyan),
      UI.tag("║  ", :cyan),
      "Easy Nerves development for Windows users",
      UI.tag("║\n", :cyan),
      UI.tag("╚═══════════════════════════════════════════════════╝\n", :cyan),
      "\n"
    ])
  end

  defp gather_configuration(opts) do
    UI.puts([
      UI.tag("📋 Configuration", :cyan),
      "\n"
    ])

    target = get_target(opts)
    wifi_config = get_wifi_configuration(opts)

    %{
      target: target,
      wifi_ssid: wifi_config.wifi_ssid,
      wifi_psk: wifi_config.wifi_psk
    }
  end

  defp get_target(opts) do
    case Keyword.get(opts, :target) do
      nil ->
        prompt_target()

      target ->
        if valid_target?(target) do
          UI.puts([
            UI.tag("✓ ", :green),
            "Target: ",
            UI.tag(target, :cyan)
          ])
          target
        else
          UI.puts([
            UI.tag("Warning: ", :yellow),
            "Invalid target '#{target}', prompting for selection..."
          ])
          prompt_target()
        end
    end
  end

  defp valid_target?(target) do
    Enum.any?(@targets, fn t -> t.value == target end)
  end

  defp prompt_target do
    UI.puts(["\n", UI.tag("Select your target device:", :cyan), "\n"])

    # Create list of targets for selection
    targets = Enum.map(@targets, & &1.value)

    selected =
      UI.select(
        targets,
        label: "Choose your device:",
        render_as: fn value ->
          target = Enum.find(@targets, fn t -> t.value == value end)
          "#{target.name} - #{target.description}"
        end
      )

    UI.puts([
      "\n",
      UI.tag("✓ ", :green),
      "Selected: ",
      UI.tag(selected, :cyan),
      "\n"
    ])

    selected
  end

  defp get_wifi_configuration(opts) do
    case {Keyword.get(opts, :wifi_ssid), Keyword.get(opts, :wifi_psk)} do
      {nil, nil} ->
        prompt_wifi_configuration()

      {ssid, psk} ->
        UI.puts([
          UI.tag("✓ ", :green),
          "WiFi configured: ",
          UI.tag(ssid || "none", :cyan)
        ])
        %{wifi_ssid: ssid || "", wifi_psk: psk || ""}
    end
  end

  defp prompt_wifi_configuration do
    UI.puts(["\n", UI.tag("WiFi Configuration", :cyan)])

    configure =
      UI.select(
        [true, false],
        label: "Would you like to configure WiFi?",
        render_as: fn
          true -> "Yes, configure WiFi now"
          false -> "No, I'll configure it later"
        end
      )

    if configure do
      UI.puts("")
      ssid = UI.input(label: "WiFi SSID") |> String.trim()
      psk = UI.input(label: "WiFi Password", secret: true) |> String.trim()

      UI.puts([
        "\n",
        UI.tag("✓ ", :green),
        "WiFi configured for SSID: ",
        UI.tag(ssid, :cyan),
        "\n"
      ])

      %{wifi_ssid: ssid, wifi_psk: psk}
    else
      UI.puts([
        "\n",
        UI.tag("ℹ ", :blue),
        "WiFi configuration skipped. You can configure it later in .devcontainer/devcontainer.json\n"
      ])
      %{wifi_ssid: "", wifi_psk: ""}
    end
  end

  defp prompt_install_deps do
    UI.puts(["\n", UI.tag("📦 Dependency Installation", :cyan), "\n"])

    choice =
      UI.select(
        [false, true],
        label: "Install dependencies now? (Recommended: No for Windows users)",
        render_as: fn
          false -> "No, install in dev container (RECOMMENDED for Windows)"
          true -> "Yes, install on host (only if Linux/Mac with Nerves installed)"
        end
      )

    UI.puts("")

    if choice do
      UI.puts([
        UI.tag("⚠️  ", :yellow),
        "Will attempt to install dependencies on host.\n",
        "(May fail on Windows - dependencies will be installed in container instead)\n"
      ])
    else
      UI.puts([
        UI.tag("✓ ", :green),
        "Dependencies will be skipped. Install them in the dev container later.\n"
      ])
    end

    choice
  end

  defp create_nerves_project(project_name, config, install_deps) do
    UI.puts([
      "\n",
      UI.tag("📦 Creating Nerves project...", :cyan),
      "\n\n"
    ])

    # Set the target environment variable
    System.put_env("MIX_TARGET", config.target)

    # Run mix nerves.new with or without deps installation
    cmd =
      if install_deps do
        "printf 'y\\n' | mix nerves.new #{project_name} --target #{config.target}"
      else
        "printf 'n\\n' | mix nerves.new #{project_name} --target #{config.target}"
      end

    case System.cmd("sh", ["-c", cmd],
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ) do
      {_, 0} ->
        UI.puts([
          "\n",
          UI.tag("✅ ", :green),
          "Nerves project created successfully\n"
        ])

        if install_deps do
          UI.puts([
            "\n",
            UI.tag("ℹ️  Note: ", :cyan),
            "If you see \"error command failed to execute\" above, that's expected on Windows.\n",
            "Dependencies will be installed inside the dev container instead.\n"
          ])
        end

      {_, code} ->
        UI.puts([
          UI.tag("Error: ", :red),
          "Failed to create Nerves project (exit code: #{code})\n",
          "Make sure nerves_bootstrap is installed: mix archive.install hex nerves_bootstrap"
        ])
        exit({:shutdown, 1})
    end
  end

  defp add_devcontainer_setup(project_name, config) do
    UI.puts([
      "\n",
      UI.tag("🐳 Adding dev container configuration...", :cyan),
      "\n"
    ])

    project_path = Path.expand(project_name)
    devcontainer_path = Path.join(project_path, ".devcontainer")

    # Create .devcontainer directory
    File.mkdir_p!(devcontainer_path)

    # Create .ssh directory
    ssh_path = Path.join(project_path, ".ssh")
    File.mkdir_p!(ssh_path)

    # Create a .gitkeep file in .ssh
    File.write!(Path.join(ssh_path, ".gitkeep"), "")

    steps = [
      {"devcontainer.json", fn -> create_devcontainer_json(devcontainer_path, config) end},
      {"docker-compose.yml", fn -> create_docker_compose(devcontainer_path) end},
      {"Dockerfile", fn -> create_dockerfile(devcontainer_path) end},
      {"VS Code workspace", fn -> create_vscode_workspace(project_path, project_name) end},
      {"VS Code settings", fn -> create_vscode_settings(project_path, project_name) end},
      {"WiFi configuration", fn -> configure_wifi_in_target(project_path, config) end},
      {"Getting started guide", fn -> create_device_guide(project_path, config) end},
      {".gitignore updates", fn -> update_gitignore(project_path) end}
    ]

    Enum.each(steps, fn {name, func} ->
      func.()
      UI.puts([
        "  ",
        UI.tag("✓ ", :green),
        name
      ])
    end)

    UI.puts([
      "\n",
      UI.tag("✅ ", :green),
      "Dev container setup complete\n"
    ])
  end

  defp create_devcontainer_json(path, config) do
    wifi_vars =
      if config.wifi_ssid != "" and config.wifi_psk != "" do
        """
        ,
            "WIFI_SSID": "#{escape_json(config.wifi_ssid)}",
            "WIFI_PSK": "#{escape_json(config.wifi_psk)}"
        """
      else
        ""
      end

    content = """
    {
      "name": "Nerves Dev Container",
      "dockerComposeFile": "docker-compose.yml",
      "service": "devcontainer",
      "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
      "mounts": [
        "source=${localWorkspaceFolder}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached"
      ],
      "customizations": {
        "vscode": {
          "extensions": [
            "JakeBecker.elixir-ls",
            "ms-azuretools.vscode-docker"
          ],
          "settings": {
            "terminal.integrated.defaultProfile.linux": "bash"
          }
        }
      },
      "remoteEnv": {
        "MIX_TARGET": "#{config.target}"#{wifi_vars}
      },
      "postCreateCommand": "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N '' -q || true && mix local.hex --force && mix local.rebar --force",
      "remoteUser": "vscode"
    }
    """

    File.write!(Path.join(path, "devcontainer.json"), content)
  end

  defp escape_json(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end

  defp create_docker_compose(path) do
    content = """
    version: '3.8'
    services:
      devcontainer:
        build:
          context: .
          dockerfile: Dockerfile
        volumes:
          - ../..:/workspaces:cached
        network_mode: "host"
        command: sleep infinity
        privileged: true
    """

    File.write!(Path.join(path, "docker-compose.yml"), content)
  end

  defp create_dockerfile(path) do
    content = ~S"""
    FROM elixir:1.18

    LABEL org.opencontainers.image.description="Elixir Nerves devcontainer for VSCode"
    LABEL org.opencontainers.image.source=https://github.com/yourusername/dev_nerves

    # Avoid warnings by switching to noninteractive
    ENV DEBIAN_FRONTEND=noninteractive

    # Configure user
    ARG USERNAME=vscode
    ARG USER_UID=1000
    ARG USER_GID=$USER_UID

    # Install dependencies for Nerves
    RUN apt-get update \
        && apt-get -y install --no-install-recommends \
        apt-utils \
        dialog \
        tree \
        git \
        iproute2 \
        procps \
        lsb-release \
        ca-certificates \
        inotify-tools \
        sudo \
        # Nerves build dependencies
        build-essential \
        automake \
        autoconf \
        libmnl-dev \
        squashfs-tools \
        ssh-askpass \
        pkg-config \
        curl \
        wget \
        # Nerves system customization dependencies
        libssl-dev \
        libncurses5-dev \
        bc \
        m4 \
        unzip \
        cmake \
        rsync \
        cpio \
        libnl-3-dev \
        # Networking tools
        nmap \
        iputils-ping \
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*

    # Install fwup (https://github.com/fwup-home/fwup)
    ENV FWUP_VERSION="1.14.0"
    RUN wget https://github.com/fwup-home/fwup/releases/download/v${FWUP_VERSION}/fwup_${FWUP_VERSION}_amd64.deb && \
        apt-get update && \
        apt-get install -y ./fwup_${FWUP_VERSION}_amd64.deb && \
        rm ./fwup_${FWUP_VERSION}_amd64.deb && \
        rm -rf /var/lib/apt/lists/*

    # Create non-root user
    RUN groupadd --gid $USER_GID $USERNAME \
        && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
        && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
        && chmod 0440 /etc/sudoers.d/$USERNAME

    # Switch to non-root user
    USER $USERNAME

    # Install Hex, Rebar, and Nerves bootstrap
    RUN mix local.hex --force \
        && mix local.rebar --force \
        && mix archive.install hex nerves_bootstrap --force \
        && mix archive.install hex phx_new --force

    # Ensure proper ownership
    RUN sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/

    # Switch back to dialog for any ad-hoc use of apt-get
    ENV DEBIAN_FRONTEND=dialog
    ENV HOME=/home/vscode

    WORKDIR /workspaces
    """

    File.write!(Path.join(path, "Dockerfile"), content)
  end

  defp create_vscode_workspace(project_path, project_name) do
    content = """
    {
      "folders": [
        {
          "path": "."
        }
      ],
      "settings": {
        "elixirLS.projectDir": ".",
        "terminal.integrated.defaultProfile.linux": "bash"
      }
    }
    """

    File.write!(Path.join(project_path, "#{project_name}.code-workspace"), content)
  end

  defp create_vscode_settings(project_path, project_name) do
    vscode_path = Path.join(project_path, ".vscode")
    File.mkdir_p!(vscode_path)

    content = """
    {
      "elixirLS.projectDir": "#{project_name}"
    }
    """

    File.write!(Path.join(vscode_path, "settings.json"), content)
  end

  defp configure_wifi_in_target(project_path, %{wifi_ssid: ssid, wifi_psk: psk})
       when ssid != "" and psk != "" do
    target_config_path = Path.join([project_path, "config", "target.exs"])

    # Read the existing target.exs file
    existing_content = File.read!(target_config_path)

    # Create the WiFi configuration
    wifi_config = """

    # WiFi Configuration
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
                 ssid: System.get_env("WIFI_SSID") || "#{escape_elixir(ssid)}",
                 psk: System.get_env("WIFI_PSK") || "#{escape_elixir(psk)}"
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
    """

    # Append WiFi configuration to the file
    File.write!(target_config_path, existing_content <> wifi_config)
  end

  defp configure_wifi_in_target(_project_path, _config), do: :ok

  defp escape_elixir(str) do
    str
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end

  defp create_device_guide(project_path, config) do
    DevNerves.Templates.FirstDeviceGuide.write(project_path, config)
  end

  defp update_gitignore(project_path) do
    gitignore_path = Path.join(project_path, ".gitignore")

    additional_entries = """

    # Dev container
    .ssh/*
    !.ssh/.gitkeep

    # Firmware images
    *.img
    *.fw
    """

    if File.exists?(gitignore_path) do
      current_content = File.read!(gitignore_path)

      unless String.contains?(current_content, ".ssh/*") do
        File.write!(gitignore_path, current_content <> additional_entries)
      end
    end
  end

  defp show_success_message(project_name, config) do
    wifi_info =
      if config[:wifi_ssid] != "" do
        [
          "  ",
          UI.tag("📡 WiFi: ", :cyan),
          config.wifi_ssid,
          "\n"
        ]
      else
        []
      end

    UI.puts([
      "\n",
      UI.tag("╔═══════════════════════════════════════════════════╗\n", :green),
      UI.tag("║  ", :green),
      UI.tag("✨ Success! Your Nerves project is ready!", :bright),
      UI.tag("     ║\n", :green),
      UI.tag("╚═══════════════════════════════════════════════════╝\n", :green),
      "\n",
      UI.tag("📁 Project Details:\n", :cyan),
      "  ",
      UI.tag("Name: ", :cyan),
      project_name,
      "\n",
      "  ",
      UI.tag("Target: ", :cyan),
      config.target,
      "\n",
      wifi_info,
      "\n",
      UI.tag("🚀 Next Steps:\n", :cyan),
      "\n",
      "  1. ",
      UI.tag("Open in VS Code:", :yellow),
      "\n",
      "     cd #{project_name}\n",
      "     code #{project_name}.code-workspace\n",
      "\n",
      "  2. ",
      UI.tag("Reopen in Dev Container:", :yellow),
      "\n",
      "     Press F1 → 'Dev Containers: Reopen in Container'\n",
      "\n",
      "  3. ",
      UI.tag("Read the guide:", :yellow),
      "\n",
      "     Open FIRST_DEVICE.md for detailed instructions\n",
      "\n",
      "  4. ",
      UI.tag("Build your firmware (inside the container):", :yellow),
      "\n",
      "     mix deps.get\n",
      "     mix firmware\n",
      "\n",
      UI.tag("💡 Important:\n", :cyan),
      "  • Dependencies are NOT installed on your host machine\n",
      "  • All builds happen INSIDE the dev container\n",
      "  • Enable host networking in Docker Desktop (Windows users)\n",
      "  • Generate SSH keys in the container: ssh-keygen\n",
      "  • Your project includes a complete getting started guide\n",
      "\n",
      UI.tag("⚠️  Remember: Always work inside the dev container!\n", :yellow),
      UI.tag("Happy hacking! 🎉\n", :green),
      "\n"
    ])
  end
end
