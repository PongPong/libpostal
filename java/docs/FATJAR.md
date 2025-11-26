# Building Cross-Platform Fat JAR

This guide explains how to build a single JAR file that includes native libraries for all platforms.

## What is a Fat JAR?

A **fat JAR** (also called uber JAR) contains:
- ✅ All Java classes
- ✅ Native libraries for multiple platforms (Linux, macOS, Windows)
- ✅ Automatic platform detection and library loading
- ✅ No external dependencies needed at runtime

Users can run your JAR on any platform without manually managing native libraries!

## Quick Start

### Option 1: Single Platform (Fastest)

Build for your current platform only:

```bash
# 1. Build native libraries
./build_jni_simple.sh

# 2. Build fat JAR
./build_fatjar.sh
```

This creates a JAR that works on your platform.

### Option 2: All Platforms (Recommended)

Build for all platforms to create a truly cross-platform JAR.

#### Step 1: Organize Platform Directories

```bash
./organize_libs.sh
```

This creates:
```
lib/
├── linux-x86_64/
├── linux-aarch64/
├── macos-x86_64/
├── macos-aarch64/
├── windows-x86_64/
└── windows-aarch64/
```

#### Step 2: Build on Each Platform

**On Linux x86_64:**
```bash
./build_jni_simple.sh
cp lib/*.so lib/linux-x86_64/
```

**On Linux ARM64:**
```bash
./build_jni_simple.sh
cp lib/*.so lib/linux-aarch64/
```

**On macOS Intel:**
```bash
./build_jni_simple.sh
cp lib/*.dylib lib/macos-x86_64/
```

**On macOS Apple Silicon (M1/M2):**
```bash
./build_jni_simple.sh
cp lib/*.dylib lib/macos-aarch64/
```

**On Windows x86_64:**
```cmd
build_jni_simple.sh
copy lib\*.dll lib\windows-x86_64\
```

**On Windows ARM64:**
```cmd
build_jni_simple.sh
copy lib\*.dll lib\windows-aarch64\
```

#### Step 3: Collect All Libraries

Copy all `lib/PLATFORM/` directories to one machine (any platform).

#### Step 4: Build Fat JAR

```bash
./build_fatjar.sh
```

This creates `libpostal-fatjar.jar` with all platforms included!

## How It Works

### Architecture

```
libpostal-fatjar.jar
├── com/libpostal/
│   ├── LibPostal.class
│   ├── AddressParserResponse.class
│   └── NativeLoader.class        ← Platform detection & loading
└── native/
    ├── linux-x86_64/
    │   ├── libpostal.so
    │   └── libpostal_jni.so
    ├── macos-x86_64/
    │   ├── libpostal.dylib
    │   └── libpostal_jni.dylib
    ├── macos-aarch64/
    │   ├── libpostal.dylib
    │   └── libpostal_jni.dylib
    └── windows-x86_64/
        ├── postal.dll
        └── postal_jni.dll
```

### Loading Process

1. **Platform Detection**: `NativeLoader` detects OS and architecture
2. **Extract**: Copies native libraries from JAR to temp directory
3. **Load**: Loads the appropriate native libraries
4. **Cleanup**: Temp files deleted on JVM exit

### Code Example

```java
import com.libpostal.LibPostal;
import com.libpostal.AddressParserResponse;

// No need to specify library path!
// NativeLoader handles everything automatically

LibPostal.setup();
LibPostal.setupParser();

AddressParserResponse response = LibPostal.parseAddress(
    "123 Main St, New York, NY 10001",
    "us"
);

for (int i = 0; i < response.components.length; i++) {
    System.out.println(response.labels[i] + ": " + response.components[i]);
}

LibPostal.teardownParser();
LibPostal.teardown();
```

## Usage

### Running the JAR

```bash
# Run the included example
java -jar libpostal-fatjar.jar

# Or run your own class
java -cp libpostal-fatjar.jar com.yourpackage.YourClass
```

### Using in Maven

```xml
<dependency>
    <groupId>com.libpostal</groupId>
    <artifactId>libpostal</artifactId>
    <version>1.0.0</version>
    <scope>system</scope>
    <systemPath>${project.basedir}/lib/libpostal-fatjar.jar</systemPath>
</dependency>
```

### Using in Gradle

```groovy
dependencies {
    implementation files('lib/libpostal-fatjar.jar')
}
```

### Using Directly

```bash
javac -cp libpostal-fatjar.jar MyApp.java
java -cp libpostal-fatjar.jar:. MyApp
```

## Supported Platforms

| Platform | Architecture | Status |
|----------|--------------|--------|
| Linux | x86_64 | ✅ Supported |
| Linux | aarch64 (ARM64) | ✅ Supported |
| macOS | x86_64 (Intel) | ✅ Supported |
| macOS | aarch64 (Apple Silicon) | ✅ Supported |
| Windows | x86_64 | ✅ Supported |
| Windows | aarch64 (ARM64) | ✅ Supported |

## Advanced: Cross-Compilation with Zig

Instead of building on each platform, use Zig to cross-compile:

```bash
# Build for all platforms
zig build cross

# Organize outputs
# (manual step - organize zig-out/* into lib/PLATFORM/)

# Build fat JAR
./build_fatjar.sh
```

**Note**: Zig cross-compilation is experimental and may require additional setup.

## Troubleshooting

### "UnsatisfiedLinkError: Library not found"

**Cause**: Native library for your platform not included in JAR

**Solution**: 
1. Check which platforms are in the JAR:
   ```bash
   jar tf libpostal-fatjar.jar | grep native/
   ```
2. Build and add your platform's libraries

### "Platform not supported"

**Cause**: Your OS/architecture combination not recognized

**Solution**: Check `NativeLoader.java` and add your platform detection

### "Failed to extract library"

**Cause**: Permissions or disk space issues

**Solution**: 
- Check `/tmp` has write permissions
- Check available disk space
- Library extracts to temp directory on first run

### Large JAR Size

**Cause**: Multiple platforms included

**Solutions**:
- Use platform-specific JARs for distribution
- Strip debug symbols from native libraries
- Compress libraries before including

## Distribution Strategies

### Strategy 1: Single Fat JAR (Recommended)

**Pros:**
- ✅ One file for all platforms
- ✅ Easy to distribute
- ✅ Works everywhere

**Cons:**
- ❌ Larger file size (~50-100MB with all platforms)

**Use when:** Distributing to unknown platforms

### Strategy 2: Platform-Specific JARs

Build separate JARs per platform:

```bash
# Build only for current platform
./build_fatjar.sh

# Rename for distribution
mv libpostal-fatjar.jar libpostal-linux-x86_64.jar
```

**Pros:**
- ✅ Smaller file size (~10-20MB per platform)
- ✅ Faster download

**Cons:**
- ❌ Must distribute multiple files
- ❌ Users must choose correct version

**Use when:** Bandwidth is critical

### Strategy 3: Download on Demand

Load libraries from a server:

```java
// Custom loader that downloads platform-specific libs
// Not included in this guide
```

**Use when:** Ultimate flexibility needed

## Testing

### Test on Multiple Platforms

```bash
# On each platform
java -jar libpostal-fatjar.jar

# Should see:
# "Running LibPostal Example..."
# "Platform: <your-platform>"
# "Libraries loaded successfully!"
```

### Test in Docker

```dockerfile
FROM openjdk:11
COPY libpostal-fatjar.jar /app/
WORKDIR /app
CMD ["java", "-jar", "libpostal-fatjar.jar"]
```

```bash
docker build -t libpostal-test .
docker run libpostal-test
```

## Size Optimization

### Strip Debug Symbols

```bash
# Linux/macOS
strip libpostal.so
strip libpostal_jni.so

# This can reduce size by 30-50%
```

### Compress Libraries

Use UPX (Universal Packer for eXecutables):

```bash
upx --best libpostal.so
```

### Include Only Needed Platforms

Edit `build_fatjar.sh` to include only specific platforms.

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build Fat JAR

on: [push]

jobs:
  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          ./build_jni_simple.sh
          mkdir -p artifacts/linux-x86_64
          cp lib/*.so artifacts/linux-x86_64/
      - uses: actions/upload-artifact@v3
        with:
          name: linux-libs
          path: artifacts/

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          ./build_jni_simple.sh
          mkdir -p artifacts/macos-x86_64
          cp lib/*.dylib artifacts/macos-x86_64/
      - uses: actions/upload-artifact@v3
        with:
          name: macos-libs
          path: artifacts/

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: |
          ./build_jni_simple.sh
          mkdir artifacts/windows-x86_64
          copy lib/*.dll artifacts/windows-x86_64/
      - uses: actions/upload-artifact@v3
        with:
          name: windows-libs
          path: artifacts/

  package:
    needs: [build-linux, build-macos, build-windows]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/download-artifact@v3
      - name: Organize libraries
        run: |
          mkdir -p lib
          cp -r linux-libs/* lib/
          cp -r macos-libs/* lib/
          cp -r windows-libs/* lib/
      - name: Build fat JAR
        run: ./build_fatjar.sh
      - uses: actions/upload-artifact@v3
        with:
          name: libpostal-fatjar
          path: libpostal-fatjar.jar
```

## Summary

| Task | Command |
|------|---------|
| Setup platform directories | `./organize_libs.sh` |
| Build current platform only | `./build_fatjar.sh` |
| Build all platforms | Build on each, then `./build_fatjar.sh` |
| Test | `java -jar libpostal-fatjar.jar` |
| Check contents | `jar tf libpostal-fatjar.jar \| grep native/` |

## Benefits

✅ **Single file distribution** - One JAR for all platforms  
✅ **No manual setup** - Native libraries load automatically  
✅ **Cross-platform** - Works on Linux, macOS, Windows  
✅ **Clean** - No library path configuration needed  
✅ **Professional** - Standard JAR that works anywhere  

---

**Ready to build your cross-platform fat JAR!** 🎉
