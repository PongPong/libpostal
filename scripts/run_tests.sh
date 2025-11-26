#!/bin/bash

set -e

echo "=== LibPostal JNI Unit Tests ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if native libraries exist
if [ ! -d "zig-out/lib" ]; then
    echo -e "${YELLOW}Warning: Native libraries not found in zig-out/lib${NC}"
    echo "Building libraries first..."
    ./build_jni.sh
    echo ""
fi

# Check if Maven is available
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}Error: Maven (mvn) not found${NC}"
    echo "Please install Maven to run tests"
    echo ""
    echo "Manual test compilation:"
    echo "  cd java"
    echo "  javac -cp junit-platform-console-standalone.jar -d build/test ..."
    exit 1
fi

echo -e "${BLUE}Running tests with Maven...${NC}"
echo ""

cd java

# Run tests
if mvn test; then
    echo ""
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    EXIT_CODE=$?
    echo ""
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ Tests completed${NC}"
    else
        echo -e "${YELLOW}⚠ Some tests failed or were skipped${NC}"
        echo ""
        echo "Common reasons:"
        echo "  - Native libraries not built (run: ./build_jni.sh)"
        echo "  - LibPostal data files not downloaded"
        echo "  - JAVA_HOME not set correctly"
        echo ""
        echo "Note: Tests gracefully skip if libraries unavailable"
    fi
    exit $EXIT_CODE
fi
