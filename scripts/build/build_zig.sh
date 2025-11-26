#!/bin/bash

set -e

echo "═══════════════════════════════════════════════════════"
echo "  LibPostal Optimized Zig Cross-Compilation Build"
echo "═══════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for Zig
if ! command -v zig &> /dev/null; then
    echo -e "${RED}Error: Zig is not installed${NC}"
    echo ""
    echo "Install Zig:"
    echo "  macOS:  brew install zig"
    echo "  Linux:  https://ziglang.org/download/"
    echo "  Or:     snap install zig --classic --beta"
    exit 1
fi

ZIG_VERSION=$(zig version)
echo -e "${BLUE}Using Zig: $ZIG_VERSION${NC}"
echo ""

# Parse arguments
BUILD_MODE="cross"
OPTIMIZE_MODE="ReleaseSmall"
ENABLE_LTO=true
STRIP=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --native)
            BUILD_MODE="native"
            shift
            ;;
        --cross)
            BUILD_MODE="cross"
            shift
            ;;
        --debug)
            OPTIMIZE_MODE="Debug"
            ENABLE_LTO=false
            STRIP=false
            shift
            ;;
        --fast)
            OPTIMIZE_MODE="ReleaseFast"
            shift
            ;;
        --small)
            OPTIMIZE_MODE="ReleaseSmall"
            shift
            ;;
        --no-lto)
            ENABLE_LTO=false
            shift
            ;;
        --no-strip)
            STRIP=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --native      Build for current platform only (default: cross)"
            echo "  --cross       Build for all platforms"
            echo "  --debug       Debug build (no optimization)"
            echo "  --fast        Optimize for speed (ReleaseFast)"
            echo "  --small       Optimize for size (ReleaseSmall, default)"
            echo "  --no-lto      Disable Link Time Optimization"
            echo "  --no-strip    Don't strip debug symbols"
            echo "  -h, --help    Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 --native           # Build for current platform"
            echo "  $0 --cross --small    # Cross-compile, optimize for size"
            echo "  $0 --native --fast    # Native build, optimize for speed"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${YELLOW}Build Configuration:${NC}"
echo "  Mode:       $BUILD_MODE"
echo "  Optimize:   $OPTIMIZE_MODE"
echo "  LTO:        $ENABLE_LTO"
echo "  Strip:      $STRIP"
echo ""

# Clean previous build
echo -e "${BLUE}Cleaning previous build...${NC}"
rm -rf zig-out zig-cache
echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

if [ "$BUILD_MODE" = "native" ]; then
    # Native build for current platform
    echo -e "${BLUE}Building for current platform...${NC}"
    echo ""
    
    ZIG_ARGS="-Doptimize=$OPTIMIZE_MODE"
    
    if [ "$ENABLE_LTO" = true ]; then
        ZIG_ARGS="$ZIG_ARGS -Dlto=true"
    fi
    
    if [ "$STRIP" = true ]; then
        ZIG_ARGS="$ZIG_ARGS -Dstrip=true"
    fi
    
    if [ "$OPTIMIZE_MODE" = "ReleaseSmall" ]; then
        ZIG_ARGS="$ZIG_ARGS -Doptimize-size=true"
    fi
    
    echo "zig build $ZIG_ARGS"
    zig build $ZIG_ARGS
    
    echo ""
    echo -e "${GREEN}✓ Native build complete${NC}"
    echo ""
    echo "Libraries built in: zig-out/lib/"
    ls -lh zig-out/lib/
    
else
    # Cross-compilation for all platforms
    echo -e "${BLUE}Cross-compiling for all platforms...${NC}"
    echo ""
    
    ZIG_ARGS="-Doptimize=$OPTIMIZE_MODE"
    
    if [ "$ENABLE_LTO" = true ]; then
        ZIG_ARGS="$ZIG_ARGS -Dlto=true"
    fi
    
    if [ "$STRIP" = true ]; then
        ZIG_ARGS="$ZIG_ARGS -Dstrip=true"
    fi
    
    if [ "$OPTIMIZE_MODE" = "ReleaseSmall" ]; then
        ZIG_ARGS="$ZIG_ARGS -Doptimize-size=true"
    fi
    
    echo "zig build cross $ZIG_ARGS"
    zig build cross $ZIG_ARGS
    
    echo ""
    echo -e "${GREEN}✓ Cross-compilation complete${NC}"
    echo ""
    
    # Show results for each platform
    echo -e "${YELLOW}Build Summary:${NC}"
    echo ""
    
    TOTAL_SIZE=0
    
    for platform_dir in zig-out/lib/*; do
        if [ -d "$platform_dir" ]; then
            platform=$(basename "$platform_dir")
            echo -e "${BLUE}Platform: $platform${NC}"
            
            # Find all library files
            for lib in "$platform_dir"/*; do
                if [ -f "$lib" ]; then
                    filename=$(basename "$lib")
                    size=$(du -h "$lib" | cut -f1)
                    size_bytes=$(stat -f%z "$lib" 2>/dev/null || stat -c%s "$lib" 2>/dev/null)
                    TOTAL_SIZE=$((TOTAL_SIZE + size_bytes))
                    
                    echo "  $filename: $size"
                fi
            done
            echo ""
        fi
    done
    
    # Convert total size to human readable
    if command -v numfmt &> /dev/null; then
        TOTAL_SIZE_HUMAN=$(numfmt --to=iec-i --suffix=B $TOTAL_SIZE)
    else
        TOTAL_SIZE_HUMAN="$((TOTAL_SIZE / 1024 / 1024))MB"
    fi
    
    echo -e "${GREEN}Total size: $TOTAL_SIZE_HUMAN${NC}"
    echo ""
fi

# Organize for fat JAR if cross-compiled
if [ "$BUILD_MODE" = "cross" ]; then
    echo -e "${BLUE}Organizing libraries for fat JAR...${NC}"
    
    # Create lib directory structure expected by build_fatjar.sh
    mkdir -p lib
    
    # Copy from Zig output to standard lib/ structure
    for platform_dir in zig-out/lib/*; do
        if [ -d "$platform_dir" ]; then
            platform=$(basename "$platform_dir")
            mkdir -p "lib/$platform"
            cp "$platform_dir"/* "lib/$platform/" 2>/dev/null || true
            echo "  ✓ $platform"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Libraries organized in lib/${NC}"
    echo ""
    echo "Ready for fat JAR build:"
    echo "  ./build_fatjar.sh"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}  Build Complete!${NC}"
echo "═══════════════════════════════════════════════════════"
echo ""

if [ "$BUILD_MODE" = "native" ]; then
    echo "Native libraries: zig-out/lib/"
    echo ""
    echo "Next steps:"
    echo "  1. Test: make test"
    echo "  2. Install: sudo make install"
else
    echo "Cross-compiled libraries: zig-out/lib/PLATFORM/"
    echo "Organized for JAR: lib/PLATFORM/"
    echo ""
    echo "Next steps:"
    echo "  1. Build fat JAR: ./build_fatjar.sh"
    echo "  2. Or build specific platform JAR"
fi
echo ""
