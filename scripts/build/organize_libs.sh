#!/bin/bash

echo "=== Organize Native Libraries for Fat JAR ==="
echo ""

# This script helps organize native libraries into platform-specific directories
# for inclusion in the fat JAR

mkdir -p lib/linux-x86_64
mkdir -p lib/linux-aarch64
mkdir -p lib/macos-x86_64
mkdir -p lib/macos-aarch64
mkdir -p lib/windows-x86_64
mkdir -p lib/windows-aarch64

echo "Created platform directories in lib/"
echo ""
echo "To build cross-platform fat JAR:"
echo ""
echo "1. Build for each platform:"
echo "   On Linux x86_64:"
echo "     ./build_jni_simple.sh"
echo "     cp lib/*.so lib/linux-x86_64/"
echo ""
echo "   On macOS x86_64:"
echo "     ./build_jni_simple.sh"
echo "     cp lib/*.dylib lib/macos-x86_64/"
echo ""
echo "   On macOS ARM64 (M1/M2):"
echo "     ./build_jni_simple.sh"
echo "     cp lib/*.dylib lib/macos-aarch64/"
echo ""
echo "   On Windows x86_64:"
echo "     build_jni_simple.sh"
echo "     cp lib/*.dll lib/windows-x86_64/"
echo ""
echo "2. Copy all lib/PLATFORM/ directories to one machine"
echo ""
echo "3. Run: ./build_fatjar.sh"
echo ""
echo "Alternative: Use Zig for cross-compilation"
echo "  zig build cross"
echo "  (organize outputs into lib/PLATFORM/ directories)"
echo ""

# Create README in lib directory
cat > lib/README.md << 'EOF'
# Native Libraries Organization

This directory contains native libraries organized by platform for the fat JAR.

## Directory Structure

```
lib/
├── linux-x86_64/
│   ├── libpostal.so
│   └── libpostal_jni.so
├── linux-aarch64/
│   ├── libpostal.so
│   └── libpostal_jni.so
├── macos-x86_64/
│   ├── libpostal.dylib
│   └── libpostal_jni.dylib
├── macos-aarch64/
│   ├── libpostal.dylib
│   └── libpostal_jni.dylib
├── windows-x86_64/
│   ├── postal.dll
│   └── postal_jni.dll
└── windows-aarch64/
    ├── postal.dll
    └── postal_jni.dll
```

## Building Libraries

### Per-Platform Build (Recommended)

Build on each platform:
```bash
./build_jni_simple.sh
```

Then copy to appropriate directory:
```bash
# Linux
cp lib/*.so lib/linux-x86_64/

# macOS Intel
cp lib/*.dylib lib/macos-x86_64/

# macOS Apple Silicon
cp lib/*.dylib lib/macos-aarch64/

# Windows
copy lib\*.dll lib\windows-x86_64\
```

### Cross-Compilation with Zig (Advanced)

```bash
zig build cross
# Organize outputs into lib/PLATFORM/ directories
```

## Building Fat JAR

Once all platforms are in place:
```bash
./build_fatjar.sh
```

This creates `libpostal-fatjar.jar` with all native libraries embedded.
EOF

echo "Created lib/README.md with instructions"
echo ""
echo "Directory structure ready!"
