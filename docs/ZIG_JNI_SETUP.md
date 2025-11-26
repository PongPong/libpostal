# LibPostal Zig + JNI Setup Complete

This document summarizes the Zig cross-compilation and JNI wrapper setup for libpostal.

## What Was Created

### 1. Build System Files

- **`build.zig`** - Modern Zig build configuration
  - Compiles all C sources to shared library
  - Supports cross-compilation to 6+ platforms
  - Builds JNI wrapper library
  - Replaces autotools/cmake complexity

- **`Makefile.zig`** - Convenient Makefile interface
  - Simple commands: `make native`, `make cross`, `make java`
  - Includes clean, install, and example targets

- **`build_jni.sh`** - Automated build script
  - Handles JNI header linking
  - Compiles Java + Native code
  - Creates JAR file

### 2. Java/JNI Code

```
java/
├── pom.xml                      # Maven build file
├── README.md                    # Java usage guide
├── src/main/java/com/libpostal/
    ├── LibPostal.java           # Main JNI interface
    ├── AddressParserResponse.java  # Response object
    └── Example.java             # Working example
```

### 3. Native JNI Wrapper

```
src/jni/
├── libpostal_jni.c             # JNI implementation
└── include/                     # JNI headers (linked)
```

### 4. Documentation

- **`BUILD_ZIG_JNI.md`** - Comprehensive build guide
- **`java/README.md`** - Java usage documentation
- **`ZIG_JNI_SETUP.md`** - This summary

## Quick Start

### Option 1: Using the build script (Recommended)

```bash
# Build everything
./build_jni.sh

# Build with cross-compilation
./build_jni.sh --cross
```

### Option 2: Using Make

```bash
# Build native + Java
make -f Makefile.zig all

# Cross-compile for all platforms
make -f Makefile.zig cross

# Run example
make -f Makefile.zig example
```

### Option 3: Using Zig directly

```bash
# Build for current platform
zig build

# Build for specific target
zig build -Dtarget=aarch64-linux

# Build all targets
zig build cross
```

### Option 4: Using Maven

```bash
cd java
mvn clean package
mvn exec:java -Dexec.mainClass="com.libpostal.Example"
```

## Build Outputs

After building, you'll have:

```
zig-out/lib/
├── libpostal.so (or .dylib, .dll)       # Core library
├── libpostal_jni.so (or .dylib, .dll)   # JNI wrapper

java/
├── libpostal.jar                         # Java classes
└── build/classes/                        # Compiled classes
```

## Supported Cross-Compilation Targets

| Platform | Architecture | Status |
|----------|--------------|--------|
| Linux | x86_64 | ✅ Supported |
| Linux | aarch64 (ARM64) | ✅ Supported |
| macOS | x86_64 (Intel) | ✅ Supported |
| macOS | aarch64 (M1/M2) | ✅ Supported |
| Windows | x86_64 | ✅ Supported |
| Windows | aarch64 | ✅ Supported |

## Using the JNI Bindings

### Basic Usage

```java
import com.libpostal.LibPostal;
import com.libpostal.AddressParserResponse;

// Initialize (required)
LibPostal.setup();
LibPostal.setupParser();

// Parse an address
AddressParserResponse result = LibPostal.parseAddress(
    "123 Main St, New York, NY 10001",
    "us"  // country code
);

// Access parsed components
for (int i = 0; i < result.components.length; i++) {
    System.out.println(result.labels[i] + ": " + result.components[i]);
}

// Cleanup (important!)
LibPostal.teardownParser();
LibPostal.teardown();
```

### Running Your Java App

```bash
# Set library path and run
java -Djava.library.path=zig-out/lib -cp java/libpostal.jar YourApp

# Or export library path
export LD_LIBRARY_PATH=zig-out/lib:$LD_LIBRARY_PATH  # Linux
export DYLD_LIBRARY_PATH=zig-out/lib:$DYLD_LIBRARY_PATH  # macOS
java -cp java/libpostal.jar YourApp
```

## Key Features

### Why Zig?

1. **Cross-compilation without toolchains**
   - Build for Windows from Linux, macOS from Windows, etc.
   - No cross-compiler setup needed
   - Single Zig installation compiles for all targets

2. **Simpler than autotools/cmake**
   - One `build.zig` file (vs. many configure scripts)
   - Declarative and readable
   - No shell scripting required

3. **Fast and reliable**
   - Incremental compilation
   - Automatic caching
   - Reproducible builds

### JNI Interface

The JNI wrapper provides:

- **Address parsing** - `parseAddress()`
- **Address expansion** - `expandAddress()`
- **Setup/teardown** - Memory management
- **Custom data directory** - `setupDatadir()`
- **Type-safe responses** - Java objects, not raw arrays

## Project Structure

```
libpostal/
├── build.zig              # Zig build configuration
├── Makefile.zig           # Make interface
├── build_jni.sh           # Automated build script
├── BUILD_ZIG_JNI.md      # Detailed build guide
├── ZIG_JNI_SETUP.md      # This file
│
├── src/
│   ├── *.c               # Original C sources
│   ├── libpostal.h       # Main C header
│   └── jni/
│       └── libpostal_jni.c  # JNI implementation
│
├── java/
│   ├── pom.xml
│   ├── README.md
│   ├── libpostal.jar     # Built JAR
│   └── src/main/java/com/libpostal/
│       ├── LibPostal.java
│       ├── AddressParserResponse.java
│       └── Example.java
│
└── zig-out/
    └── lib/              # Built libraries
```

## Next Steps

### 1. Download LibPostal Data

LibPostal requires trained model data to function:

```bash
# Follow instructions in main README.md to download data files
# Or specify custom location:
LibPostal.setupDatadir("/path/to/libpostal/data");
```

### 2. Test the Build

```bash
# Run the example program
make -f Makefile.zig example

# Or manually:
cd examples
./run_example.sh
```

### 3. Integrate into Your Project

**Maven:**
```xml
<dependency>
    <groupId>com.libpostal</groupId>
    <artifactId>libpostal-jni</artifactId>
    <version>1.0.0</version>
    <scope>system</scope>
    <systemPath>${project.basedir}/lib/libpostal.jar</systemPath>
</dependency>
```

**Gradle:**
```groovy
dependencies {
    implementation files('libs/libpostal.jar')
}
```

### 4. Deploy

When deploying, include:
- `libpostal.jar` - Java classes
- `libpostal.so`/`.dylib`/`.dll` - Core library
- `libpostal_jni.so`/`.dylib`/`.dll` - JNI wrapper
- LibPostal data files

## Troubleshooting

### Build Errors

**Zig not found:**
```bash
brew install zig  # macOS
# or download from https://ziglang.org/download/
```

**JAVA_HOME not set:**
```bash
export JAVA_HOME=$(/usr/libexec/java_home)  # macOS
export JAVA_HOME=/usr/lib/jvm/default-java   # Linux
```

### Runtime Errors

**UnsatisfiedLinkError:**
- Library not in java.library.path
- Use `-Djava.library.path=zig-out/lib`
- Or set `LD_LIBRARY_PATH` / `DYLD_LIBRARY_PATH`

**Data files not found:**
- Download libpostal data
- Use `LibPostal.setupDatadir()` to specify location

## Benefits Over Other Approaches

### vs. Traditional Make/Autotools
- ✅ Cross-compilation without toolchains
- ✅ Faster compilation
- ✅ Cleaner, more maintainable
- ✅ No dependency hell

### vs. CMake
- ✅ Simpler syntax
- ✅ Built-in cross-compilation
- ✅ No generator step
- ✅ Faster configure phase

### vs. Gradle/Maven Native Plugins
- ✅ More control
- ✅ Better cross-compilation
- ✅ Smaller build files
- ✅ Language-agnostic

## Contributing

To add new JNI methods:

1. Declare in `java/src/main/java/com/libpostal/LibPostal.java`
2. Implement in `src/jni/libpostal_jni.c`
3. Follow naming: `Java_com_libpostal_LibPostal_methodName`
4. Rebuild with `./build_jni.sh`

## License

Same as libpostal - MIT License

## Support

- LibPostal Issues: https://github.com/openvenues/libpostal/issues
- Zig Documentation: https://ziglang.org/documentation/
- JNI Specification: https://docs.oracle.com/javase/8/docs/technotes/guides/jni/

---

**Setup completed successfully!** 🎉

You now have a modern, cross-platform build system for libpostal with Java bindings.
