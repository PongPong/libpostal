# LibPostal Java JNI Wrapper

This directory contains Java bindings for libpostal using JNI (Java Native Interface).

## Building

### Prerequisites

1. Install Zig (0.11 or later): https://ziglang.org/download/
2. JDK 8 or later installed
3. Set `JAVA_HOME` environment variable

### Build with Zig

Build for your current platform:

```bash
zig build
```

Build for all supported platforms (cross-compilation):

```bash
zig build cross
```

This will create shared libraries in `zig-out/lib/`:
- `libpostal.so` / `libpostal.dylib` / `postal.dll` - Core libpostal library
- `libpostal_jni.so` / `libpostal_jni.dylib` / `postal_jni.dll` - JNI wrapper

### Compile Java Classes

```bash
cd java
javac -d build/classes src/main/java/com/libpostal/*.java
```

### Create JAR

```bash
cd java
jar cf libpostal.jar -C build/classes .
```

## Usage

### Basic Example

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

// Or use map interface
var map = response.toMap();
System.out.println("Road: " + map.get("road"));

// Cleanup
LibPostal.teardownParser();
LibPostal.teardown();
```

### More Examples

For complete working examples, see the `examples/` directory:

```bash
cd examples
./run_example.sh
```

Examples include:
- Basic address parsing
- Address expansion
- Multiple country formats
- Map interface usage
- Batch processing

See `examples/README.md` for details.

## Library Path

Make sure the native libraries are in your Java library path:

### Linux/macOS
```bash
export LD_LIBRARY_PATH=/path/to/zig-out/lib:$LD_LIBRARY_PATH
# or for macOS
export DYLD_LIBRARY_PATH=/path/to/zig-out/lib:$DYLD_LIBRARY_PATH

java -Djava.library.path=/path/to/zig-out/lib -cp libpostal.jar YourApp
```

### Windows
```cmd
set PATH=C:\path\to\zig-out\lib;%PATH%
java -Djava.library.path=C:\path\to\zig-out\lib -cp libpostal.jar YourApp
```

## Cross-Compilation Targets

The Zig build supports the following targets:
- Linux x86_64
- Linux aarch64 (ARM64)
- macOS x86_64
- macOS aarch64 (Apple Silicon)
- Windows x86_64
- Windows aarch64

Each target will produce architecture-specific binaries in `zig-out/lib/`.
