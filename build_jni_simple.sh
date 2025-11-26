#!/bin/bash

set -e

echo "=== LibPostal JNI Build (Autotools Method) ==="
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
    echo ""
    echo "Example:"
    echo "  export JAVA_HOME=\$(/usr/libexec/java_home)  # macOS"
    echo "  export JAVA_HOME=/usr/lib/jvm/default-java    # Linux"
    exit 1
fi

echo -e "${BLUE}Using JAVA_HOME: $JAVA_HOME${NC}"

# Detect OS for JNI headers
OS=$(uname -s)
case "$OS" in
    Linux*)
        JNI_MD="linux"
        LIB_EXT="so"
        ;;
    Darwin*)
        JNI_MD="darwin"
        LIB_EXT="dylib"
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

# Step 1: Check if libpostal is built
echo -e "\n${BLUE}Step 1: Checking libpostal build...${NC}"

if [ ! -f "src/.libs/libpostal.${LIB_EXT}" ] && [ ! -f "src/.libs/libpostal.a" ]; then
    echo -e "${YELLOW}LibPostal not built yet${NC}"
    echo ""
    echo "Building libpostal with autotools..."
    
    # Check for required tools
    for tool in autoconf automake libtool; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}Error: $tool not found${NC}"
            echo "Please install autotools:"
            echo "  macOS:  brew install automake libtool pkg-config"
            echo "  Linux:  apt-get install autoconf automake libtool pkg-config"
            exit 1
        fi
    done
    
    # Bootstrap and build
    if [ ! -f "configure" ]; then
        echo "Running bootstrap..."
        ./bootstrap.sh
    fi
    
    if [ ! -f "Makefile" ]; then
        echo "Running configure..."
        ./configure --prefix=/usr/local
    fi
    
    echo "Building libpostal..."
    make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    echo -e "${GREEN}✓ LibPostal built${NC}"
else
    echo -e "${GREEN}✓ LibPostal already built${NC}"
fi

# Step 2: Setup JNI headers
echo -e "\n${BLUE}Step 2: Setting up JNI headers...${NC}"

mkdir -p src/jni/include

if [ ! -f "$JAVA_HOME/include/jni.h" ]; then
    echo -e "${RED}Error: jni.h not found in JAVA_HOME${NC}"
    echo "Check JAVA_HOME path: $JAVA_HOME"
    exit 1
fi

ln -sf "$JAVA_HOME/include/jni.h" src/jni/include/jni.h
ln -sf "$JAVA_HOME/include/$JNI_MD/jni_md.h" src/jni/include/jni_md.h

echo -e "${GREEN}✓ JNI headers linked${NC}"

# Step 3: Compile JNI wrapper
echo -e "\n${BLUE}Step 3: Compiling JNI wrapper...${NC}"

JNI_CFLAGS="-I./src -I./src/jni/include -I$JAVA_HOME/include -I$JAVA_HOME/include/$JNI_MD -fPIC -std=c99"
JNI_LDFLAGS="-L./src/.libs -lpostal -shared"

if [ "$OS" = "Darwin" ]; then
    JNI_LDFLAGS="$JNI_LDFLAGS -install_name @rpath/libpostal_jni.dylib"
fi

gcc $JNI_CFLAGS -c src/jni/libpostal_jni.c -o src/jni/libpostal_jni.o

if [ "$OS" = "Darwin" ]; then
    gcc src/jni/libpostal_jni.o $JNI_LDFLAGS -o src/jni/libpostal_jni.dylib
else
    gcc src/jni/libpostal_jni.o $JNI_LDFLAGS -o src/jni/libpostal_jni.so
fi

echo -e "${GREEN}✓ JNI wrapper compiled${NC}"

# Step 4: Copy libraries to standard location
echo -e "\n${BLUE}Step 4: Organizing libraries...${NC}"

mkdir -p lib
cp src/.libs/libpostal.${LIB_EXT}* lib/ 2>/dev/null || true
cp src/.libs/libpostal.a lib/ 2>/dev/null || true
cp src/jni/libpostal_jni.${LIB_EXT} lib/

echo -e "${GREEN}✓ Libraries copied to lib/${NC}"

# Step 5: Compile Java classes
echo -e "\n${BLUE}Step 5: Compiling Java classes...${NC}"

mkdir -p java/build/classes
javac -d java/build/classes java/src/main/java/com/libpostal/*.java

echo -e "${GREEN}✓ Java classes compiled${NC}"

# Step 6: Create JAR
echo -e "\n${BLUE}Step 6: Creating JAR...${NC}"

cd java
jar cf libpostal.jar -C build/classes .
cd ..

echo -e "${GREEN}✓ JAR created: java/libpostal.jar${NC}"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo "Native libraries:"
echo "  lib/libpostal.${LIB_EXT}"
echo "  lib/libpostal_jni.${LIB_EXT}"
echo ""
echo "Java library:"
echo "  java/libpostal.jar"
echo ""
echo "To run examples:"
echo "  export LD_LIBRARY_PATH=./lib:\$LD_LIBRARY_PATH  # Linux"
echo "  export DYLD_LIBRARY_PATH=./lib:\$DYLD_LIBRARY_PATH  # macOS"
echo "  cd examples && ./run_example.sh"
echo ""
echo "Or:"
echo "  java -Djava.library.path=./lib -cp java/libpostal.jar com.libpostal.Example"
echo ""
