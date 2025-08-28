#!/bin/bash

# Test runner script for Public-Domain Reader
# Runs all tests (unit, integration, and E2E)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test flags
RUN_UNIT=true
RUN_E2E=true
RUN_FLUTTER_WEB=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --unit-only)
            RUN_E2E=false
            shift
            ;;
        --e2e-only)
            RUN_UNIT=false
            shift
            ;;
        --with-web)
            RUN_FLUTTER_WEB=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "Test runner for Public-Domain Reader"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --unit-only     Run only unit tests"
            echo "  --e2e-only      Run only E2E tests"
            echo "  --with-web      Start Flutter web server for E2E tests"
            echo "  --verbose       Verbose output"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to run Rust tests
run_rust_tests() {
    print_info "Running Rust unit tests..."
    cd crates/pdreader_core
    
    if [[ $VERBOSE == true ]]; then
        cargo test --release --verbose
    else
        cargo test --release
    fi
    
    cd ../..
    print_status "Rust tests completed"
}

# Function to run Flutter tests
run_flutter_tests() {
    print_info "Running Flutter unit tests..."
    cd apps/app_flutter
    
    if [[ $VERBOSE == true ]]; then
        flutter test --coverage --verbose
    else
        flutter test --coverage
    fi
    
    cd ../..
    print_status "Flutter tests completed"
}

# Function to check code formatting
check_formatting() {
    print_info "Checking code formatting..."
    
    # Check Rust formatting
    cd crates/pdreader_core
    if ! cargo fmt -- --check; then
        print_error "Rust code is not properly formatted"
        echo "Run: cargo fmt"
        exit 1
    fi
    cd ../..
    
    # Check Flutter formatting
    cd apps/app_flutter
    if ! dart format --set-exit-if-changed lib/ test/; then
        print_error "Flutter code is not properly formatted"
        echo "Run: dart format lib/ test/"
        exit 1
    fi
    cd ../..
    
    print_status "Code formatting check passed"
}

# Function to run linting
run_linting() {
    print_info "Running code analysis..."
    
    # Run Rust clippy
    cd crates/pdreader_core
    if [[ $VERBOSE == true ]]; then
        cargo clippy --verbose -- -D warnings
    else
        cargo clippy -- -D warnings
    fi
    cd ../..
    
    # Run Flutter analysis
    cd apps/app_flutter
    flutter analyze
    cd ../..
    
    print_status "Code analysis completed"
}

# Function to start Flutter web server
start_flutter_web() {
    print_info "Starting Flutter web server..."
    cd apps/app_flutter
    
    # Kill any existing Flutter processes on port 3000
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    
    # Start Flutter web server in background
    flutter run -d web-server --web-port=3000 --release &
    FLUTTER_PID=$!
    
    # Wait for server to start
    print_info "Waiting for Flutter web server to start..."
    for i in {1..30}; do
        if curl -s http://localhost:3000 > /dev/null 2>&1; then
            print_status "Flutter web server is ready"
            cd ../..
            return 0
        fi
        sleep 2
    done
    
    print_error "Flutter web server failed to start"
    kill $FLUTTER_PID 2>/dev/null || true
    cd ../..
    exit 1
}

# Function to run E2E tests
run_e2e_tests() {
    if ! command -v npm > /dev/null 2>&1; then
        print_warning "npm not found, skipping E2E tests"
        return 0
    fi
    
    print_info "Running E2E tests with Playwright..."
    cd tests/playwright
    
    # Check if dependencies are installed
    if [ ! -d "node_modules" ]; then
        print_info "Installing E2E test dependencies..."
        npm install
        npx playwright install --with-deps
    fi
    
    # Start Flutter web server if requested
    if [[ $RUN_FLUTTER_WEB == true ]]; then
        cd ../..
        start_flutter_web
        FLUTTER_STARTED=true
        cd tests/playwright
    fi
    
    # Run Playwright tests
    if [[ $VERBOSE == true ]]; then
        npm run test -- --reporter=list
    else
        npm run test
    fi
    
    cd ../..
    print_status "E2E tests completed"
    
    # Stop Flutter web server if we started it
    if [[ $FLUTTER_STARTED == true ]]; then
        kill $FLUTTER_PID 2>/dev/null || true
        print_info "Flutter web server stopped"
    fi
}

# Function to generate test report
generate_report() {
    print_info "Generating test report..."
    
    # Combine coverage reports if they exist
    if [ -f "apps/app_flutter/coverage/lcov.info" ]; then
        print_status "Flutter coverage report: apps/app_flutter/coverage/lcov.info"
    fi
    
    # Show Playwright report if it exists
    if [ -f "tests/playwright/playwright-report/index.html" ]; then
        print_status "E2E test report: tests/playwright/playwright-report/index.html"
        
        if command -v open > /dev/null 2>&1; then
            # macOS
            open tests/playwright/playwright-report/index.html
        elif command -v xdg-open > /dev/null 2>&1; then
            # Linux
            xdg-open tests/playwright/playwright-report/index.html
        elif command -v start > /dev/null 2>&1; then
            # Windows
            start tests/playwright/playwright-report/index.html
        fi
    fi
}

# Main test function
main() {
    echo "🧪 Running Public-Domain Reader test suite..."
    echo ""
    
    # Always check formatting and linting
    check_formatting
    run_linting
    
    # Run unit tests if requested
    if [[ $RUN_UNIT == true ]]; then
        echo ""
        echo "📋 Running unit tests..."
        run_rust_tests
        run_flutter_tests
    fi
    
    # Run E2E tests if requested
    if [[ $RUN_E2E == true ]]; then
        echo ""
        echo "🎭 Running E2E tests..."
        run_e2e_tests
    fi
    
    echo ""
    echo "📊 Generating reports..."
    generate_report
    
    echo ""
    print_status "All tests completed successfully! 🎉"
    echo ""
    echo "Summary:"
    [[ $RUN_UNIT == true ]] && echo "  ✅ Unit tests: PASSED"
    [[ $RUN_E2E == true ]] && echo "  ✅ E2E tests: PASSED"
    echo "  ✅ Code formatting: PASSED"
    echo "  ✅ Code analysis: PASSED"
}

# Handle script interruption
cleanup() {
    print_warning "Test run interrupted"
    
    # Kill Flutter web server if running
    if [[ $FLUTTER_PID ]]; then
        kill $FLUTTER_PID 2>/dev/null || true
        print_info "Cleaned up Flutter web server"
    fi
    
    exit 1
}

trap cleanup INT TERM

# Run main function
main "$@"