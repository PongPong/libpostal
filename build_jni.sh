#!/bin/bash

set -e

echo "=== LibPostal JNI Build Script ==="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for JAVA_HOME
if [ -z "$JAVA_HOME" ]; then
    echo -e "${RED}Error: JAVA_HOME is not set${NC}"
    echo "Please set JAVA_HOME to your JDK installation path"
    exit 1
fi

echo -e "${BLUE}Using JAVA_HOME: $JAVA_HOME${NC}"

# Check if libpostal is already built with autotools
if [ ! -f "src/.libs/libpostal.a" ] && [ ! -f "src/.libs/libpostal.so" ] && [ ! -f "src/.libs/libpostal.dylib" ]; then
    echo -e "${YELLOW}Warning: LibPostal not built with autotools${NC}"
    echo -e "${YELLOW}The Zig build requires libpostal to be configured first${NC}"
    echo ""
    echo "Please build libpostal first using autotools:"
    echo "  ./bootstrap.sh"
    echo "  ./configure"
    echo "  make"
    echo ""
    echo "Then run this script again."
    echo ""
    echo -e "${BLUE}Alternatively, this will build only Java components...${NC}"
fi

# Detect OS
OS=$(uname -s)
case "$OS" in
    Linux*)     
        JNI_INCLUDE="$JAVA_HOME/include"
        JNI_INCLUDE_OS="$JAVA_HOME/include/linux"
        ;;
    Darwin*)    
        JNI_INCLUDE="$JAVA_HOME/include"
        JNI_INCLUDE_OS="$JAVA_HOME/include/darwin"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        JNI_INCLUDE="$JAVA_HOME/include"
        JNI_INCLUDE_OS="$JAVA_HOME/include/win32"
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

# Create JNI include directory in project
mkdir -p src/jni/include

# Copy or link JNI headers
if [ -d "$JNI_INCLUDE" ]; then
    echo -e "${BLUE}Creating symlinks to JNI headers...${NC}"
    ln -sf "$JNI_INCLUDE/jni.h" src/jni/include/jni.h
    ln -sf "$JNI_INCLUDE_OS/jni_md.h" src/jni/include/jni_md.h
    echo -e "${GREEN}✓ JNI headers linked${NC}"
else
    echo -e "${RED}Error: JNI headers not found at $JNI_INCLUDE${NC}"
    exit 1
fi

# Compile Java classes
echo -e "\n${BLUE}Compiling Java classes...${NC}"
mkdir -p java/build/classes
javac -d java/build/classes java/src/main/java/com/libpostal/*.java
echo -e "${GREEN}✓ Java classes compiled${NC}"

# Generate JNI headers (optional, if using javah in older JDK)
# For JDK 8+, the C code already matches the expected signatures

# Build native libraries with Zig
echo -e "\n${BLUE}Building native libraries with Zig...${NC}"
if zig build 2>&1 | tee /tmp/zig_build.log | grep -q "error:"; then
    echo -e "${RED}✗ Zig build failed${NC}"
    echo ""
    echo -e "${YELLOW}This is likely because libpostal needs to be built with autotools first.${NC}"
    echo ""
    echo "LibPostal requires system dependencies and configuration."
    echo "Please build using the standard method:"
    echo ""
    echo "  1. Install dependencies:"
    echo "     macOS:  brew install automake libtool pkg-config"
    echo "     Linux:  apt-get install automake libtool pkg-config libsnappy-dev"
    echo ""
    echo "  2. Build libpostal:"
    echo "     ./bootstrap.sh"
    echo "     ./configure"
    echo "     make"
    echo ""
    echo "  3. Then build JNI wrapper:"
    echo "     cd src/jni"
    echo "     make (if Makefile exists)"
    echo ""
    echo -e "${BLUE}For now, Java classes are compiled successfully.${NC}"
    echo "Native libraries will need to be built separately."
    exit 1
fi
echo -e "${GREEN}✓ Native libraries built${NC}"

# Create JAR
echo -e "\n${BLUE}Creating JAR file...${NC}"
cd java
jar cf libpostal.jar -C build/classes .
echo -e "${GREEN}✓ JAR created: java/libpostal.jar${NC}"
cd ..

# Optional: Build for all platforms
if [ "$1" == "--cross" ]; then
    echo -e "\n${BLUE}Cross-compiling for all platforms...${NC}"
    zig build cross
    echo -e "${GREEN}✓ Cross-compilation complete${NC}"
fi

echo -e "\n${GREEN}=== Build Complete ===${NC}"
echo -e "Native libraries: ${BLUE}zig-out/lib/${NC}"
echo -e "Java JAR: ${BLUE}java/libpostal.jar${NC}"
echo -e "\nTo run the example:"
echo -e "  ${BLUE}java -Djava.library.path=zig-out/lib -cp java/libpostal.jar com.libpostal.Example${NC}"
