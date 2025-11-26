#!/bin/bash

set -e

echo "=== LibPostal Optimized JNI Build ==="
echo ""
echo "This build is optimized for size - perfect for fat JAR distribution"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for JAVA_HOME
if [ -z "$JAVA_HOME" ]; then
    echo -e "${RED}Error: JAVA_HOME is not set${NC}"
    echo "Please set JAVA_HOME to your JDK installation path"
    exit 1
fi

echo -e "${BLUE}Using JAVA_HOME: $JAVA_HOME${NC}"

# Detect OS
OS=$(uname -s)
case "$OS" in
    Linux*)
        JNI_MD="linux"
        LIB_EXT="so"
        STRIP_CMD="strip --strip-all"
        ;;
    Darwin*)
        JNI_MD="darwin"
        LIB_EXT="dylib"
        STRIP_CMD="strip -x"
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Optimization Settings:${NC}"
echo "  • Size optimization (-Os)"
echo "  • Link-time optimization (-flto)"
echo "  • Dead code elimination"
echo "  • Debug symbols stripped"
echo ""

# Optimization flags for size
export CFLAGS="-Os -flto -ffunction-sections -fdata-sections -DNDEBUG"

# Platform-specific linker flags
if [ "$OS" = "Darwin" ]; then
    export LDFLAGS="-Wl,-dead_strip"
else
    export LDFLAGS="-Wl,--gc-sections"
fi

# Step 1: Check if libpostal is built
echo -e "${BLUE}Step 1: Checking libpostal build...${NC}"

if [ ! -f "src/.libs/libpostal.${LIB_EXT}" ] && [ ! -f "src/.libs/libpostal.a" ]; then
    echo -e "${YELLOW}LibPostal not built yet${NC}"
    echo "Building with optimization flags..."
    
    # Bootstrap and build
    if [ ! -f "configure" ]; then
        echo "Running bootstrap..."
        ./bootstrap.sh
    fi
    
    if [ ! -f "Makefile" ]; then
        echo "Running configure with optimization..."
        ./configure --prefix=/usr/local
    fi
    
    echo "Building libpostal (this may take a few minutes)..."
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    echo -e "${GREEN}✓ LibPostal built with optimization${NC}"
else
    echo -e "${GREEN}✓ LibPostal already built${NC}"
fi

# Show original size
ORIGINAL_SIZE=$(du -sh src/.libs/libpostal.${LIB_EXT} 2>/dev/null | cut -f1)
echo "  Original size: $ORIGINAL_SIZE"

# Step 2: Setup JNI headers
echo -e "\n${BLUE}Step 2: Setting up JNI headers...${NC}"

mkdir -p src/jni/include

if [ ! -f "$JAVA_HOME/include/jni.h" ]; then
    echo -e "${RED}Error: jni.h not found in JAVA_HOME${NC}"
    exit 1
fi

ln -sf "$JAVA_HOME/include/jni.h" src/jni/include/jni.h
ln -sf "$JAVA_HOME/include/$JNI_MD/jni_md.h" src/jni/include/jni_md.h

echo -e "${GREEN}✓ JNI headers linked${NC}"

# Step 3: Compile JNI wrapper with optimization
echo -e "\n${BLUE}Step 3: Compiling JNI wrapper (optimized)...${NC}"

JNI_CFLAGS="-I./src -I./src/jni/include -I$JAVA_HOME/include -I$JAVA_HOME/include/$JNI_MD -fPIC -std=c99 $CFLAGS"
JNI_LDFLAGS="-L./src/.libs -lpostal -shared $LDFLAGS"

if [ "$OS" = "Darwin" ]; then
    JNI_LDFLAGS="$JNI_LDFLAGS -install_name @rpath/libpostal_jni.dylib"
fi

gcc $JNI_CFLAGS -c src/jni/libpostal_jni.c -o src/jni/libpostal_jni.o

if [ "$OS" = "Darwin" ]; then
    gcc src/jni/libpostal_jni.o $JNI_LDFLAGS -o src/jni/libpostal_jni.dylib
else
    gcc src/jni/libpostal_jni.o $JNI_LDFLAGS -o src/jni/libpostal_jni.so
fi

echo -e "${GREEN}✓ JNI wrapper compiled with optimization${NC}"

# Step 4: Strip debug symbols
echo -e "\n${BLUE}Step 4: Stripping debug symbols...${NC}"

mkdir -p lib
cp src/.libs/libpostal.${LIB_EXT}* lib/ 2>/dev/null || true
cp src/.libs/libpostal.a lib/ 2>/dev/null || true
cp src/jni/libpostal_jni.${LIB_EXT} lib/

echo "  Stripping libpostal..."
$STRIP_CMD lib/libpostal.${LIB_EXT} 2>/dev/null || true

echo "  Stripping libpostal_jni..."
$STRIP_CMD lib/libpostal_jni.${LIB_EXT} 2>/dev/null || true

STRIPPED_SIZE=$(du -sh lib/libpostal.${LIB_EXT} 2>/dev/null | cut -f1)
echo -e "${GREEN}✓ Debug symbols stripped${NC}"
echo "  Size after strip: $STRIPPED_SIZE"

# Step 5: Optional UPX compression
echo -e "\n${BLUE}Step 5: Optional compression...${NC}"

if command -v upx &> /dev/null; then
    echo -e "${YELLOW}UPX found. Compress? This will reduce size by ~40-60% but slow startup.${NC}"
    echo "Type 'yes' to compress, or press Enter to skip: "
    read -r COMPRESS
    
    if [ "$COMPRESS" = "yes" ]; then
        echo "Compressing with UPX (this may take a minute)..."
        upx --best --lzma lib/libpostal.${LIB_EXT} 2>/dev/null || upx --best lib/libpostal.${LIB_EXT}
        upx --best --lzma lib/libpostal_jni.${LIB_EXT} 2>/dev/null || upx --best lib/libpostal_jni.${LIB_EXT}
        
        COMPRESSED_SIZE=$(du -sh lib/libpostal.${LIB_EXT} 2>/dev/null | cut -f1)
        echo -e "${GREEN}✓ Libraries compressed${NC}"
        echo "  Size after UPX: $COMPRESSED_SIZE"
    else
        echo "Skipping UPX compression"
    fi
else
    echo "UPX not found. Install with:"
    echo "  macOS: brew install upx"
    echo "  Linux: apt-get install upx"
    echo ""
    echo "Skipping compression..."
fi

echo -e "${GREEN}✓ Optimization complete${NC}"

# Step 6: Compile Java classes
echo -e "\n${BLUE}Step 6: Compiling Java classes...${NC}"

mkdir -p java/build/classes
javac -d java/build/classes java/src/main/java/com/libpostal/*.java

echo -e "${GREEN}✓ Java classes compiled${NC}"

# Step 7: Create JAR
echo -e "\n${BLUE}Step 7: Creating JAR...${NC}"

cd java
jar cf libpostal.jar -C build/classes .
cd ..

echo -e "${GREEN}✓ JAR created: java/libpostal.jar${NC}"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Optimized Build Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "Native libraries (optimized for size):"
echo "  lib/libpostal.${LIB_EXT}"
echo "  lib/libpostal_jni.${LIB_EXT}"
echo ""
echo "Size comparison:"
echo "  Original:  $ORIGINAL_SIZE"
echo "  Stripped:  $STRIPPED_SIZE"
if [ -n "$COMPRESSED_SIZE" ]; then
    echo "  Compressed: $COMPRESSED_SIZE"
fi
echo ""
echo "Java library:"
echo "  java/libpostal.jar"
echo ""
echo "These optimized libraries are perfect for:"
echo "  • Fat JAR distribution (./build_fatjar.sh)"
echo "  • Embedded systems"
echo "  • Docker containers"
echo "  • Cloud deployments"
echo ""
echo "To run examples:"
echo "  export DYLD_LIBRARY_PATH=./lib:\$DYLD_LIBRARY_PATH  # macOS"
echo "  export LD_LIBRARY_PATH=./lib:\$LD_LIBRARY_PATH      # Linux"
echo "  cd examples && ./run_example.sh"
echo ""
