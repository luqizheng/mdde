# MDDE Command Line Tool

[![Build and Release](https://github.com/luqizheng/mdde/actions/workflows/build.yml/badge.svg)](https://github.com/luqizheng/mdde/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Languages**: [English](README_EN.md) | [中文](README.md)

A cross-platform command-line tool written in Rust for managing Docker multi-language development environments.

## 🚀 Features

- **Docker Integration**: Complete Docker and Docker Compose management
- **Template System**: Download development environment templates from remote servers
- **Multi-format Output**: Support for Table, JSON, YAML format output
- **Internationalization**: Built-in multi-language support system
- **System Diagnostics**: Built-in environment checking and diagnostic features
- **Configuration Management**: Flexible environment variable configuration system

## 🏗️ System Architecture

### Architecture Overview

MDDE is a template-based Docker multi-language development environment management tool that downloads docker-compose templates from remote servers via HTTP client for rapid environment setup.

### How It Works

1. **Initialize Configuration**: Use `mdde init` to set remote template server address
2. **Create Environment**: Use `mdde create` to download specified docker-compose templates
3. **Environment Management**: Manage container lifecycle through Docker Compose
4. **Configuration Storage**: All configurations are stored in `.mdde/cfg.env` file

### File Structure

```
Project Directory/
├── .mdde/
│   ├── cfg.env              # Environment variable configuration
│   └── docker-compose.yml   # Docker Compose configuration
├── .gitignore              # Auto-updated to ignore .mdde/ directory
└── Other project files...
```

### Template Server

Default template server: `https://raw.githubusercontent.com/luqizheng/mdde-dockerifle/refs/heads/main`

Supported development environment types:
- **dotnet**: .NET development environments (sdk6.0, sdk8.0, sdk9.0, etc.)
- **java**: Java development environments (openjdk11, openjdk17, openjdk21, etc.)
- **nodejs**: Node.js development environments (node18, node20, node22, etc.)
- **python**: Python development environments (python311, yolo-11, etc.)

## 🛠️ Installation and Setup

### Method 1: Download Pre-compiled Binaries (Recommended)

1. **Go to [Releases page](https://github.com/luqizheng/mdde/releases/latest) and download the binary for your platform**

   - **Linux (x64)**: `mdde-linux-x64` or `mdde-linux-x64.tar.gz`
   - **Windows (x64)**: `mdde-windows-x64.exe` or `mdde-windows-x64.zip`
   - **macOS (Intel)**: `mdde-macos-x64` or `mdde-macos-x64.tar.gz`
   - **macOS (Apple Silicon)**: `mdde-macos-arm64` or `mdde-macos-arm64.tar.gz`

2. **Install the binary**

   **Linux/macOS:**
   ```bash
   # Rename and move to PATH directory after download
   mv mdde-linux-x64 /usr/local/bin/mdde
   chmod +x /usr/local/bin/mdde
   
   # Or for macOS
   mv mdde-macos-x64 /usr/local/bin/mdde
   chmod +x /usr/local/bin/mdde
   ```

   **Windows:**
   ```powershell
   # Rename mdde-windows-x64.exe to mdde.exe
   # and move it to a directory in PATH environment variable
   ```

3. **Verify installation**
   ```bash
   mdde --help
   mdde version
   ```

### Method 2: Build from Source

#### Prerequisites
- Rust 1.70+
- Docker (installed and added to PATH)
- Docker Compose (installed and added to PATH)

#### Build Steps

1. **Clone the project**
   ```bash
   git clone https://github.com/luqizheng/mdde.git
   cd mdde/mdde-cmd
   ```

2. **Build the project**
   ```bash
   cargo build --release
   ```

3. **Install to system**
   ```bash
   cargo install --path .
   ```

## ⚙️ Configuration Management

### Configuration File

MDDE uses `.mdde/cfg.env` file to store configuration information:

```bash
host=https://raw.githubusercontent.com/luqizheng/mdde-dockerifle/refs/heads/main
container_name=my-project
app_port=8080
workspace=/path/to/workspace
```

### Configuration Options

- **host**: Template server address
- **container_name**: Container name
- **app_port**: Application port number
- **workspace**: Workspace directory path

### Automatic Configuration

- When creating `.mdde/cfg.env` file, MDDE automatically updates `.gitignore` file
- Ignores the entire `.mdde/` directory to avoid committing configuration files to version control

## 🔌 Usage

### Basic Workflow

```bash
# 1. Initialize configuration
mdde init

# 2. Create development environment
mdde create dotnet/sdk8.0 --name my-dotnet-app --app_port 8080:80

# 3. Start environment
mdde start

# 4. Check status
mdde status

# 5. Enter container
mdde exec

# 6. Stop environment
mdde stop
```

### Command Reference

#### Initialization
```bash
cd source_code
# Interactive initialization
mdde init

# Specify server address
mdde init --host https://your-server.com
```

#### Create Environment
```bash
# Interactive creation
mdde create

# Create with parameters, when source code and mdde execution directories differ, use --workspace to specify source location
mdde create java/openjdk17 --name my-java-app --app_port 8080:8080 --workspace ./src
# Or
mdde create java/openjdk17
```

#### Environment Management
```bash
# Start environment (foreground)
mdde start

# Start environment (background)
mdde start --detach

# Stop environment
mdde stop

# Stop and remove containers
mdde stop --remove

# Restart environment
mdde restart
```

#### Container Operations
```bash
# Enter container (default bash)
mdde exec

# Specify shell
mdde exec /bin/sh

# Execute commands in container
mdde run ls -la
mdde run npm install
```

#### Status and Logs
```bash
# View status (table format)
mdde status

# JSON format output
mdde status --format json

# YAML format output
mdde status --format yaml

# View logs
mdde logs

# View last 50 lines of logs
mdde logs 50

# Follow logs in real-time
mdde logs --follow
```

#### Cleanup Operations
```bash
# Clean all unused resources
mdde clean --all

# Clean only images
mdde clean --images

# Clean only containers
mdde clean --containers

# Clean only volumes
mdde clean --volumes
```

#### System Diagnostics
```bash
# Check system environment
mdde doctor
```

#### Environment Variable Management
```bash
# View all environment variables
mdde env --ls

# Set environment variable
mdde env --set "host=https://new-server.com"

# Delete environment variable
mdde env --del container_name
```

## 🧪 Testing

```bash
# Run all tests
cargo test

# Run specific tests
cargo test config

# Run integration tests
cargo test --test integration_tests
```

## 📁 Project Structure

```
mdde-cmd/
├── src/
│   ├── main.rs              # Main program entry point
│   ├── lib.rs               # Library entry point
│   ├── cli.rs               # CLI definition and command routing
│   ├── config.rs            # Configuration management (.mdde/cfg.env)
│   ├── error.rs             # Error type definitions
│   ├── http.rs              # HTTP client implementation
│   ├── docker.rs            # Docker command wrapper
│   ├── i18n.rs              # Internationalization support
│   ├── utils.rs             # Utility functions
│   └── commands/            # Command implementations
│       ├── mod.rs
│       ├── init.rs          # Initialize command
│       ├── create.rs        # Create environment command
│       ├── start.rs         # Start command
│       ├── stop.rs          # Stop command
│       ├── status.rs        # Status view command
│       ├── logs.rs          # Log view command
│       ├── exec.rs          # Enter container command
│       ├── run.rs           # Execute command
│       ├── clean.rs         # Cleanup command
│       ├── doctor.rs        # System diagnostics command
│       ├── env.rs           # Environment variable management command
│       ├── version.rs       # Version info command
│       └── restart.rs       # Restart command
├── examples/                # Example programs
├── tests/                   # Integration tests
├── Cargo.toml               # Project configuration
└── README.md                # Project documentation
```

## 🔒 Technology Stack

- **Language**: Rust 2021 Edition
- **CLI Framework**: clap 4.4 (derive feature)
- **Async Runtime**: tokio 1.35 (full features)
- **HTTP Client**: reqwest 0.11 (json, multipart features)
- **Serialization**: serde, serde_json, serde_yaml, toml
- **Error Handling**: thiserror, anyhow
- **Logging**: tracing, tracing-subscriber
- **Others**: colored, indicatif, dirs, walkdir

## 🚨 Important Notes

### System Requirements
1. **Docker**: Must have Docker installed and available in PATH
2. **Docker Compose**: Must have Docker Compose installed
3. **Network Connection**: Need access to template server

### Usage Notes
1. **Configuration File**: `.mdde/cfg.env` contains sensitive configuration, automatically added to `.gitignore`
2. **Permission Requirements**: Some Docker operations may require administrator privileges
3. **Port Conflicts**: Be careful to avoid port conflicts when creating environments

### Troubleshooting
```bash
# Use diagnostic command to check environment
mdde doctor

# Check Docker status
docker --version
docker-compose --version
docker info
```

## 🚀 CI/CD Pipeline

This project uses GitHub Actions for automated building and releasing:

### Automatic Building
- **Trigger Conditions**: Push to `main`, `develop` branches or create Pull Request
- **Build Platforms**: Linux x64, Windows x64, macOS Intel, macOS Apple Silicon
- **Build Artifacts**: Automatically uploaded to GitHub Actions Artifacts

### Automatic Release
- **Trigger Conditions**: Push Git tags in `v*` format (e.g., `v1.0.0`)
- **Release Content**: 
  - Cross-platform binary files
  - Compressed archive formats (tar.gz and zip)
  - Auto-generated release notes

### Creating New Versions
1. **Update version number**
   ```bash
   # Update version number in mdde-cmd/Cargo.toml
   sed -i 's/version = "0.1.0"/version = "0.2.0"/' mdde-cmd/Cargo.toml
   ```

2. **Commit and create tag**
   ```bash
   git add .
   git commit -m "chore: bump version to v0.2.0"
   git tag v0.2.0
   git push origin main --tags
   ```

3. **Automatic release**
   - GitHub Actions will automatically build all platforms
   - Create new Release page
   - Upload binary files and archives

## 🤝 Contributing

Issues and Pull Requests are welcome!

### Contribution Guidelines

1. **Report Issues**: Use [Issue template](https://github.com/luqizheng/mdde/issues/new) to report bugs or request new features
2. **Code Contributions**: 
   - Fork the project and create feature branches
   - Ensure code passes all tests and checks
   - Submit Pull Request for review
3. **Documentation Improvements**: Welcome improvements to documentation and example code

### Development Workflow
```bash
# 1. Fork and clone project
git clone https://github.com/your-username/mdde.git
cd mdde

# 2. Create feature branch
git checkout -b feature/your-feature

# 3. Develop and test
cd mdde-cmd
cargo test
cargo clippy -- -D warnings
cargo fmt -- --check

# 4. Commit changes
git commit -m "feat: add your feature"
git push origin feature/your-feature

# 5. Create Pull Request
```

## 📄 License

MIT License
