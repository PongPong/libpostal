#!/bin/bash

set -e

echo "=== LibPostal Cross-Platform Fat JAR Builder ==="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
JAR_NAME="libpostal-fatjar.jar"
BUILD_DIR="java/build"
CLASSES_DIR="$BUILD_DIR/classes"
NATIVE_DIR="$BUILD_DIR/native"
MANIFEST_FILE="$BUILD_DIR/MANIFEST.MF"

echo -e "${BLUE}Step 1: Checking for native libraries...${NC}"
echo ""

# Array of platforms to include
declare -A PLATFORMS=(
    ["linux-x86_64"]="lib/linux-x86_64"
    ["linux-aarch64"]="lib/linux-aarch64"
    ["macos-x86_64"]="lib/macos-x86_64"
    ["macos-aarch64"]="lib/macos-aarch64"
    ["windows-x86_64"]="lib/windows-x86_64"
    ["windows-aarch64"]="lib/windows-aarch64"
)

# Check current platform libraries
CURRENT_LIBS=0
if [ -d "lib" ]; then
    CURRENT_LIBS=$(find lib -name "libpostal*" -o -name "postal*.dll" 2>/dev/null | wc -l)
fi

if [ $CURRENT_LIBS -eq 0 ] && [ ! -d "zig-out/lib" ]; then
    echo -e "${YELLOW}Warning: No native libraries found${NC}"
    echo ""
    echo "You need to build native libraries first."
    echo "Choose one of:"
    echo ""
    echo "  1. Build for current platform only:"
    echo "     ./build_jni_simple.sh"
    echo ""
    echo "  2. Cross-compile for all platforms (requires Zig):"
    echo "     zig build cross"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo -e "${GREEN}✓ Found native libraries${NC}"
echo ""

# Step 2: Compile Java classes
echo -e "${BLUE}Step 2: Compiling Java classes...${NC}"

mkdir -p "$CLASSES_DIR"
javac -d "$CLASSES_DIR" \
    java/src/main/java/com/libpostal/*.java

echo -e "${GREEN}✓ Java classes compiled${NC}"
echo ""

# Step 3: Organize native libraries
echo -e "${BLUE}Step 3: Organizing native libraries...${NC}"

mkdir -p "$NATIVE_DIR"

# Function to copy libraries for a platform
copy_platform_libs() {
    local platform=$1
    local source_dir=$2
    local dest_dir="$NATIVE_DIR/$platform"
    
    mkdir -p "$dest_dir"
    
    # Copy based on platform
    if [[ $platform == windows-* ]]; then
        cp "$source_dir"/postal*.dll "$dest_dir/" 2>/dev/null && return 0
    elif [[ $platform == macos-* ]]; then
        cp "$source_dir"/libpostal*.dylib "$dest_dir/" 2>/dev/null && return 0
    elif [[ $platform == linux-* ]]; then
        cp "$source_dir"/libpostal*.so "$dest_dir/" 2>/dev/null && return 0
    fi
    
    return 1
}

# Copy libraries from lib/ if they exist
PLATFORMS_INCLUDED=0

if [ -d "lib" ]; then
    # Check for organized platform directories
    for platform in "${!PLATFORMS[@]}"; do
        if [ -d "lib/$platform" ]; then
            if copy_platform_libs "$platform" "lib/$platform"; then
                echo "  ✓ Added $platform"
                PLATFORMS_INCLUDED=$((PLATFORMS_INCLUDED + 1))
            fi
        fi
    done
    
    # If no platform directories, assume current platform in lib/
    if [ $PLATFORMS_INCLUDED -eq 0 ] && [ $CURRENT_LIBS -gt 0 ]; then
        # Detect current platform
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        ARCH=$(uname -m)
        
        case "$OS" in
            linux) PLATFORM_OS="linux" ;;
            darwin) PLATFORM_OS="macos" ;;
            *) PLATFORM_OS="unknown" ;;
        esac
        
        case "$ARCH" in
            x86_64|amd64) PLATFORM_ARCH="x86_64" ;;
            aarch64|arm64) PLATFORM_ARCH="aarch64" ;;
            *) PLATFORM_ARCH="unknown" ;;
        esac
        
        if [ "$PLATFORM_OS" != "unknown" ] && [ "$PLATFORM_ARCH" != "unknown" ]; then
            CURRENT_PLATFORM="${PLATFORM_OS}-${PLATFORM_ARCH}"
            if copy_platform_libs "$CURRENT_PLATFORM" "lib"; then
                echo "  ✓ Added $CURRENT_PLATFORM (current platform)"
                PLATFORMS_INCLUDED=$((PLATFORMS_INCLUDED + 1))
            fi
        fi
    fi
fi

# Copy from zig-out if it exists
if [ -d "zig-out/lib" ]; then
    # Zig cross-compilation output is typically flat, need to organize
    echo "  Note: zig-out/lib found but cross-platform organization needed"
    echo "  Run 'zig build cross' and organize libraries into lib/PLATFORM/ directories"
fi

if [ $PLATFORMS_INCLUDED -eq 0 ]; then
    echo -e "${YELLOW}Warning: No platform-specific libraries organized${NC}"
    echo "Including current platform only..."
    
    # Create current platform entry
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$OS" in
        linux) PLATFORM_OS="linux" ;;
        darwin) PLATFORM_OS="macos" ;;
        *) PLATFORM_OS="unknown" ;;
    esac
    
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) PLATFORM_ARCH="x86_64" ;;
        aarch64|arm64) PLATFORM_ARCH="aarch64" ;;
        *) PLATFORM_ARCH="unknown" ;;
    esac
    
    CURRENT_PLATFORM="${PLATFORM_OS}-${PLATFORM_ARCH}"
    dest_dir="$NATIVE_DIR/$CURRENT_PLATFORM"
    mkdir -p "$dest_dir"
    
    if [ -d "lib" ]; then
        find lib -name "libpostal*" -o -name "postal*.dll" | while read libfile; do
            cp "$libfile" "$dest_dir/"
        done
        PLATFORMS_INCLUDED=1
        echo "  ✓ Added $CURRENT_PLATFORM"
    fi
fi

echo ""
echo -e "${GREEN}✓ Included $PLATFORMS_INCLUDED platform(s)${NC}"
echo ""

# Step 4: Create manifest
echo -e "${BLUE}Step 4: Creating manifest...${NC}"

cat > "$MANIFEST_FILE" << EOF
Manifest-Version: 1.0
Created-By: LibPostal Fat JAR Builder
Main-Class: com.libpostal.Example
Implementation-Title: LibPostal
Implementation-Version: 1.0.0
Multi-Release: true
EOF

echo -e "${GREEN}✓ Manifest created${NC}"
echo ""

# Step 5: Build fat JAR
echo -e "${BLUE}Step 5: Building fat JAR...${NC}"

cd "$BUILD_DIR"
jar cfm "$JAR_NAME" MANIFEST.MF -C classes . -C . native/
cd ../..

mv "$BUILD_DIR/$JAR_NAME" .

echo -e "${GREEN}✓ Fat JAR created${NC}"
echo ""

# Step 6: Summary
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Fat JAR Build Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "Output: $JAR_NAME"
echo "Size: $(du -h $JAR_NAME | cut -f1)"
echo "Platforms: $PLATFORMS_INCLUDED"
echo ""
echo "Contents:"
jar tf "$JAR_NAME" | grep -E "(\.class|native/)" | head -20
echo "..."
echo ""
echo "To run:"
echo "  java -jar $JAR_NAME"
echo ""
echo "To use in your project:"
echo "  Add $JAR_NAME to your classpath"
echo "  Native libraries load automatically!"
echo ""
