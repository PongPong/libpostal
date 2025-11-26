# Java/JNI Bindings for libpostal

This directory contains Java bindings and utilities for libpostal.

## Documentation

- [docs/BUILD_METHODS.md](docs/BUILD_METHODS.md) - Comparison of different build methods
- [docs/BUILD_COMPARISON.md](docs/BUILD_COMPARISON.md) - Build performance comparison
- [docs/OPTIMIZATION.md](docs/OPTIMIZATION.md) - Optimization strategies for size and performance
- [docs/ZIG_BUILD.md](docs/ZIG_BUILD.md) - Detailed Zig build system documentation
- [docs/ZIG_QUICK.md](docs/ZIG_QUICK.md) - Quick start guide for Zig builds
- [docs/FATJAR.md](docs/FATJAR.md) - Detailed fat JAR build documentation
- [docs/FATJAR_QUICK.md](docs/FATJAR_QUICK.md) - Quick start guide for fat JAR

## Build Scripts

Build scripts are located in `../scripts/build/`:

- `build_zig.sh` - Build native libraries using Zig
- `build_jni.sh` - Build JNI wrappers
- `build_jni_optimized.sh` - Build optimized JNI wrappers
- `build_jni_simple.sh` - Simple JNI build
- `build_fatjar.sh` - Build cross-platform fat JAR
- `organize_libs.sh` - Organize built libraries

## Quick Start

### Build Native Library with Zig

From the repository root:

```bash
./scripts/build/build_zig.sh
```

### Build Fat JAR

From the repository root:

```bash
./scripts/build/build_fatjar.sh
```

### Basic Usage

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

## Examples

See the `examples/` directory for complete working examples.

See the documentation files above for more details.
