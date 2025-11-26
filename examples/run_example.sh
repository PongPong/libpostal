#!/bin/bash

set -e

echo "=== LibPostal JNI Example Runner ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if JAR exists
if [ ! -f "../java/libpostal.jar" ]; then
    echo -e "${RED}Error: libpostal.jar not found${NC}"
    echo "Please build first: cd .. && ./build_jni.sh"
    exit 1
fi

# Check if native libraries exist
if [ ! -d "../zig-out/lib" ]; then
    echo -e "${RED}Error: Native libraries not found${NC}"
    echo "Please build first: cd .. && ./build_jni.sh"
    exit 1
fi

# Create build directory
mkdir -p build

# Compile example
echo -e "${BLUE}Compiling example...${NC}"
javac -cp ../java/libpostal.jar -d build java/com/libpostal/Example.java

if [ $? -ne 0 ]; then
    echo -e "${RED}Compilation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Compilation successful${NC}"
echo ""

# Determine library path
if [ -d "../zig-out/lib" ]; then
    LIB_PATH="../zig-out/lib"
elif [ -d "../lib" ]; then
    LIB_PATH="../lib"
else
    echo -e "${RED}Error: No library directory found${NC}"
    echo "Expected: ../zig-out/lib or ../lib"
    exit 1
fi

# Run example
echo -e "${BLUE}Running example...${NC}"
echo -e "${BLUE}Using libraries from: $LIB_PATH${NC}"
echo ""
java -Djava.library.path=$LIB_PATH -cp build:../java/libpostal.jar com.libpostal.Example

echo ""
echo -e "${GREEN}✓ Example completed${NC}"
