# Building LibPostal with Zig and JNI

This guide explains how to build libpostal as a shared library using Zig for cross-compilation and create JNI bindings for Java.

## Overview

The build system uses:
- **Zig** - Cross-platform C compiler and build system
- **JNI** - Java Native Interface for Java bindings
- **build.zig** - Zig build configuration for cross-compilation

## Prerequisites

### 1. Install Zig

Download and install Zig 0.11 or later from: https://ziglang.org/download/

```bash
# macOS (using Homebrew)
brew install zig

# Linux (download binary)
wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
tar xf zig-linux-x86_64-0.11.0.tar.xz
export PATH=$PATH:$(pwd)/zig-linux-x86_64-0.11.0
```

### 2. Install JDK (for JNI)

You need JDK 8 or later:

```bash
# macOS
brew install openjdk

# Linux (Ubuntu/Debian)
sudo apt-get install openjdk-11-jdk

# Set JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home)  # macOS
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64  # Linux
```

## Quick Start

### Build Everything (Native + JNI)

```bash
./build_jni.sh
```

This will:
1. Link JNI headers
2. Compile Java classes
3. Build native libraries (libpostal + JNI wrapper)
4. Create JAR file

### Build for All Platforms (Cross-Compilation)

```bash
./build_jni.sh --cross
```

This creates binaries for:
- Linux (x86_64, aarch64)
- macOS (x86_64, Apple Silicon)
- Windows (x86_64, aarch64)

## Manual Build Steps

### Step 1: Build Native Libraries

```bash
# Build for current platform
zig build

# Build for all platforms
zig build cross

# Build with optimization
zig build -Doptimize=ReleaseFast
```

Output in `zig-out/lib/`:
- `libpostal.so` / `libpostal.dylib` / `postal.dll`
- `libpostal_jni.so` / `libpostal_jni.dylib` / `postal_jni.dll`

### Step 2: Compile Java Classes

```bash
cd java
mkdir -p build/classes
javac -d build/classes src/main/java/com/libpostal/*.java
```

### Step 3: Create JAR

```bash
cd java
jar cf libpostal.jar -C build/classes .
```

## Usage

### Run Example Program

```bash
# Make sure libpostal data is downloaded first (see main README.md)
# Then run:
cd examples
./run_example.sh
```

For more examples, see the `examples/` directory.

### Use in Your Java Project

```java
import com.libpostal.LibPostal;
import com.libpostal.AddressParserResponse;

// Initialize
LibPostal.setup();
LibPostal.setupParser();

// Parse address
AddressParserResponse response = LibPostal.parseAddress(
    "123 Main St, New York, NY 10001",
    "us"
);

// Access results
for (int i = 0; i < response.components.length; i++) {
    System.out.println(response.labels[i] + ": " + response.components[i]);
}

// Cleanup
LibPostal.teardownParser();
LibPostal.teardown();
```

## Cross-Compilation

Zig makes cross-compilation trivial. The `build.zig` supports these targets:

| Platform | Architecture | Output |
|----------|--------------|--------|
| Linux | x86_64 | `libpostal.so`, `libpostal_jni.so` |
| Linux | aarch64 | `libpostal.so`, `libpostal_jni.so` |
| macOS | x86_64 | `libpostal.dylib`, `libpostal_jni.dylib` |
| macOS | aarch64 | `libpostal.dylib`, `libpostal_jni.dylib` |
| Windows | x86_64 | `postal.dll`, `postal_jni.dll` |
| Windows | aarch64 | `postal.dll`, `postal_jni.dll` |

### Building for Specific Target

```bash
# Linux ARM64
zig build -Dtarget=aarch64-linux

# macOS Apple Silicon
zig build -Dtarget=aarch64-macos

# Windows x64
zig build -Dtarget=x86_64-windows
```

## Project Structure

```
libpostal/
├── build.zig                    # Zig build configuration
├── build_jni.sh                 # Build script for JNI
├── BUILD_ZIG_JNI.md            # This file
├── src/
│   ├── *.c                      # C source files
│   ├── libpostal.h              # Main header
│   └── jni/
│       ├── libpostal_jni.c      # JNI wrapper implementation
│       └── include/             # JNI headers (symlinked)
├── java/
│   ├── README.md
│   ├── libpostal.jar            # Built JAR
│   └── src/main/java/com/libpostal/
│       ├── LibPostal.java       # Main JNI class
│       ├── AddressParserResponse.java
│       └── Example.java         # Example usage
└── zig-out/
    └── lib/                     # Built libraries
```

## Advantages of Zig Build System

1. **Cross-compilation**: Build for any platform from any platform
2. **No toolchain setup**: Zig includes C compiler for all targets
3. **Fast**: Incremental compilation and caching
4. **Simple**: Single `build.zig` file replaces autotools/cmake
5. **Reproducible**: Same inputs always produce same outputs

## Troubleshooting

### JNI Headers Not Found

Make sure `JAVA_HOME` is set:
```bash
export JAVA_HOME=$(/usr/libexec/java_home)  # macOS
export JAVA_HOME=/usr/lib/jvm/default-java   # Linux
```

### Library Not Found at Runtime

Set library path:
```bash
# Linux
export LD_LIBRARY_PATH=./zig-out/lib:$LD_LIBRARY_PATH

# macOS
export DYLD_LIBRARY_PATH=./zig-out/lib:$DYLD_LIBRARY_PATH

# Or use -Djava.library.path
java -Djava.library.path=./zig-out/lib -cp java/libpostal.jar YourApp
```

### Data Files Missing

LibPostal requires trained model data. Download it first:
```bash
# See main README.md for data download instructions
# Or set custom data directory:
LibPostal.setupDatadir("/path/to/libpostal/data");
```

## Build Options

```bash
# Debug build
zig build -Doptimize=Debug

# Release with debug info
zig build -Doptimize=ReleaseSafe

# Release optimized
zig build -Doptimize=ReleaseFast

# Release small binary
zig build -Doptimize=ReleaseSmall

# Verbose output
zig build --verbose
```

## Contributing

When adding new JNI methods:

1. Add native method declaration in `LibPostal.java`
2. Implement in `src/jni/libpostal_jni.c`
3. Follow JNI naming convention: `Java_com_libpostal_LibPostal_methodName`
4. Rebuild with `./build_jni.sh`

## License

Same as libpostal (MIT License)
