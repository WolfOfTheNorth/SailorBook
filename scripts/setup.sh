#!/bin/bash

# Setup script for Public-Domain Reader development environment
# This script installs all dependencies and sets up the development environment

set -e

echo "🚀 Setting up Public-Domain Reader development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Flutter installation
check_flutter() {
    if command_exists flutter; then
        FLUTTER_VERSION=$(flutter --version | head -n 1 | cut -d ' ' -f 2)
        print_status "Flutter found: $FLUTTER_VERSION"
        
        # Check if version is recent enough
        if [[ $(echo "$FLUTTER_VERSION 3.16.0" | tr " " "\n" | sort -V | head -n1) != "3.16.0" ]]; then
            print_warning "Flutter version $FLUTTER_VERSION is older than required 3.16.0"
            print_warning "Please update Flutter: flutter upgrade"
        fi
    else
        print_error "Flutter not found. Please install Flutter first:"
        echo "  Visit: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
}

# Check Rust installation
check_rust() {
    if command_exists rustc; then
        RUST_VERSION=$(rustc --version | cut -d ' ' -f 2)
        print_status "Rust found: $RUST_VERSION"
    else
        print_error "Rust not found. Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
        print_status "Rust installed successfully"
    fi
}

# Check Node.js installation (for testing)
check_node() {
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_status "Node.js found: $NODE_VERSION"
    else
        print_warning "Node.js not found. This is optional but required for E2E testing."
        print_warning "Install Node.js from: https://nodejs.org/"
    fi
}

# Install Flutter dependencies
install_flutter_deps() {
    print_status "Installing Flutter dependencies..."
    cd apps/app_flutter
    flutter pub get
    cd ../..
}

# Build Rust core
build_rust_core() {
    print_status "Building Rust core library..."
    cd crates/pdreader_core
    cargo build --release
    cd ../..
}

# Generate Flutter-Rust bridge
generate_bridge() {
    print_status "Generating Flutter-Rust bridge..."
    cd crates/pdreader_core
    
    # Install flutter_rust_bridge_codegen if not present
    if ! command_exists flutter_rust_bridge_codegen; then
        cargo install flutter_rust_bridge_codegen
    fi
    
    cargo run --bin codegen
    cd ../..
}

# Install test dependencies
install_test_deps() {
    if command_exists npm; then
        print_status "Installing test dependencies..."
        cd tests/playwright
        npm install
        
        if command_exists npx; then
            npx playwright install --with-deps
            print_status "Playwright browsers installed"
        else
            print_warning "npx not found, skipping Playwright browser installation"
        fi
        
        cd ../..
    else
        print_warning "npm not found, skipping test dependencies"
    fi
}

# Enable Flutter platforms
enable_flutter_platforms() {
    print_status "Enabling Flutter platforms..."
    cd apps/app_flutter
    
    flutter config --enable-web
    
    # Enable desktop platforms based on OS
    case "$OSTYPE" in
        darwin*)
            flutter config --enable-macos-desktop
            ;;
        linux*)
            flutter config --enable-linux-desktop
            ;;
        msys*|cygwin*)
            flutter config --enable-windows-desktop
            ;;
    esac
    
    cd ../..
}

# Run basic tests
run_tests() {
    print_status "Running basic tests..."
    
    # Rust tests
    cd crates/pdreader_core
    cargo test --release
    cd ../..
    
    # Flutter tests
    cd apps/app_flutter
    flutter test
    cd ../..
    
    print_status "All tests passed!"
}

# Main setup function
main() {
    echo "📋 Checking prerequisites..."
    check_flutter
    check_rust
    check_node
    
    echo ""
    echo "📦 Installing dependencies..."
    install_flutter_deps
    
    echo ""
    echo "🔧 Building Rust core..."
    build_rust_core
    
    echo ""
    echo "🌉 Generating Flutter-Rust bridge..."
    generate_bridge
    
    echo ""
    echo "📱 Configuring Flutter platforms..."
    enable_flutter_platforms
    
    echo ""
    echo "🧪 Installing test dependencies..."
    install_test_deps
    
    echo ""
    echo "✅ Running basic tests..."
    run_tests
    
    echo ""
    echo "🎉 Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Run the app: cd apps/app_flutter && flutter run -d web-server --web-port=3000"
    echo "  2. Open browser: http://localhost:3000"
    echo "  3. Run tests: cd tests/playwright && npm run test"
    echo ""
    echo "For more information, see README.md"
}

# Run main function
main "$@"