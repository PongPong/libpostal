# LibPostal JNI Build Methods

There are two ways to build the LibPostal JNI wrapper, depending on your needs.

## Quick Comparison

| Method | Best For | Prerequisites | Cross-Compile |
|--------|----------|---------------|---------------|
| **Autotools** (Recommended) | Local development | autotools, gcc | No |
| **Zig** (Experimental) | Cross-platform builds | Zig, pre-built libpostal | Yes |

## Method 1: Autotools Build (Recommended) ⭐

This is the standard, reliable method that works on all platforms.

### Prerequisites

**macOS:**
```bash
brew install automake libtool pkg-config
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install autoconf automake libtool pkg-config libsnappy-dev
```

### Build Steps

```bash
# Set JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home)  # macOS
# or
export JAVA_HOME=/usr/lib/jvm/default-java   # Linux

# Run the build script
./build_jni_simple.sh
```

This will:
1. Build libpostal with autotools (if not already built)
2. Compile the JNI wrapper with gcc
3. Compile Java classes
4. Create the JAR file

### Output

```
lib/
├── libpostal.so (or .dylib)
├── libpostal_jni.so (or .dylib)

java/
└── libpostal.jar
```

### Running Examples

```bash
# Set library path
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH  # Linux
export DYLD_LIBRARY_PATH=./lib:$DYLD_LIBRARY_PATH  # macOS

# Run
cd examples
./run_example.sh
```

## Method 2: Zig Build (Experimental)

This method uses Zig to build everything from scratch and supports cross-compilation.

### Prerequisites

```bash
# Install Zig
brew install zig  # macOS

# or download from https://ziglang.org/download/
```

### Current Limitations

⚠️ **The Zig build currently fails** because:
- LibPostal has system dependencies (snappy, etc.)
- Some source files need generated headers from autotools
- The build system needs to be configured first

### Potential Solutions

1. **Pre-build libpostal** with autotools, then use Zig only for JNI:
   ```bash
   # Build libpostal first
   ./bootstrap.sh
   ./configure
   make
   
   # Then try Zig build
   zig build
   ```

2. **Vendor dependencies**: Include snappy and other deps in the Zig build

3. **Use Zig for cross-compilation only**: Build on one platform, cross-compile for others

## Troubleshooting

### build_jni.sh fails with "snappy-c.h not found"

**Solution**: Use `build_jni_simple.sh` instead, which uses autotools:
```bash
./build_jni_simple.sh
```

### "configure: command not found"

**Solution**: Install autotools:
```bash
# macOS
brew install automake libtool

# Linux
sudo apt-get install autoconf automake libtool
```

### "JAVA_HOME is not set"

**Solution**: Set JAVA_HOME environment variable:
```bash
# macOS
export JAVA_HOME=$(/usr/libexec/java_home)

# Linux - find your Java installation
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Add to ~/.bashrc or ~/.zshrc to make permanent
```

### Libraries not found at runtime

**Solution**: Set library path:
```bash
# Linux
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH

# macOS
export DYLD_LIBRARY_PATH=./lib:$DYLD_LIBRARY_PATH

# Or use -Djava.library.path
java -Djava.library.path=./lib -cp java/libpostal.jar YourApp
```

## Recommended Workflow

### For Development

Use the autotools method:
```bash
./build_jni_simple.sh
```

### For Testing

```bash
./run_tests.sh
```

### For Distribution

Build on each target platform using autotools:
```bash
# On each platform (Linux, macOS, Windows)
./build_jni_simple.sh

# Package the native libraries with your application
```

## Future: Improving Zig Build

To make the Zig build work, we need to:

1. **Vendor dependencies**:
   - Include snappy source
   - Include other system dependencies

2. **Generate required files**:
   - Run autotools configure to generate config headers
   - Or manually create necessary headers

3. **Update build.zig**:
   - Add dependency paths
   - Handle platform-specific compilation

## Manual Build (Advanced)

If both scripts fail, you can build manually:

```bash
# 1. Build libpostal
./bootstrap.sh
./configure
make

# 2. Setup JNI headers
mkdir -p src/jni/include
ln -s $JAVA_HOME/include/jni.h src/jni/include/
ln -s $JAVA_HOME/include/darwin/jni_md.h src/jni/include/  # macOS
# or
ln -s $JAVA_HOME/include/linux/jni_md.h src/jni/include/   # Linux

# 3. Compile JNI wrapper
cd src/jni
gcc -I../.. -Iinclude -I$JAVA_HOME/include \
    -I$JAVA_HOME/include/darwin \
    -c libpostal_jni.c -o libpostal_jni.o -fPIC

gcc libpostal_jni.o -L../../src/.libs -lpostal -shared \
    -o libpostal_jni.dylib  # or .so on Linux

# 4. Compile Java
cd ../../java
mkdir -p build/classes
javac -d build/classes src/main/java/com/libpostal/*.java
jar cf libpostal.jar -C build/classes .

# 5. Copy libraries
mkdir -p ../lib
cp ../src/.libs/libpostal.* ../lib/
cp ../src/jni/libpostal_jni.* ../lib/
```

## Summary

| Task | Command |
|------|---------|
| **Build (Recommended)** | `./build_jni_simple.sh` |
| **Build (Zig - Experimental)** | `./build_jni.sh` |
| **Run Tests** | `./run_tests.sh` |
| **Run Examples** | `cd examples && ./run_example.sh` |
| **Clean** | `make clean` |

For most users, **use build_jni_simple.sh** which relies on the standard autotools build system.
