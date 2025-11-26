# Fat JAR Quick Reference

## What You Get

A **single JAR file** that:
- âœ… Works on Linux, macOS, Windows
- âœ… Includes native libraries for all platforms
- âœ… Loads libraries automatically
- âœ… No user setup required

## Quick Build (Current Platform Only)

```bash
./build_jni_simple.sh    # Build native libraries
./build_fatjar.sh        # Create fat JAR
```

Result: `libpostal-fatjar.jar` (works on your platform)

## Full Build (All Platforms)

### 1. Setup Directories
```bash
./organize_libs.sh
```

### 2. Build on Each Platform

**Linux x86_64:**
```bash
./build_jni_simple.sh
cp lib/*.so lib/linux-x86_64/
```

**macOS Intel:**
```bash
./build_jni_simple.sh
cp lib/*.dylib lib/macos-x86_64/
```

**macOS M1/M2:**
```bash
./build_jni_simple.sh
cp lib/*.dylib lib/macos-aarch64/
```

**Windows:**
```cmd
build_jni_simple.sh
copy lib\*.dll lib\windows-x86_64\
```

### 3. Collect & Build

Copy all `lib/PLATFORM/` dirs to one machine, then:

```bash
./build_fatjar.sh
```

Result: `libpostal-fatjar.jar` (works everywhere!)

## Usage

### Run It
```bash
java -jar libpostal-fatjar.jar
```

### Use It
```java
import com.libpostal.LibPostal;

// No library path needed!
LibPostal.setup();
LibPostal.setupParser();

AddressParserResponse result = 
    LibPostal.parseAddress("123 Main St", "us");
```

### Include It

**Maven:**
```xml
<dependency>
    <systemPath>libpostal-fatjar.jar</systemPath>
</dependency>
```

**Gradle:**
```groovy
implementation files('libpostal-fatjar.jar')
```

## Commands

| Task | Command |
|------|---------|
| Setup | `./organize_libs.sh` |
| Build (current) | `./build_fatjar.sh` |
| Build (all) | Build on each â†’ `./build_fatjar.sh` |
| Run | `java -jar libpostal-fatjar.jar` |
| Test | `jar tf libpostal-fatjar.jar \| grep native/` |

## Files Created

- `NativeLoader.java` - Auto platform detection & loading
- `build_fatjar.sh` - Fat JAR builder
- `organize_libs.sh` - Platform directory setup
- `FATJAR.md` - Full documentation

## Platforms Supported

bœ“ Linux x86_64  
bœ“ Linux ARM64  
bœ“ macOS Intel  
bœ“ macOS Apple Silicon  
bœ“ Windows x86_64  
bœ“ Windows ARM64  

## See Also

- `FATJAR.md` - Complete guide with examples
- `BUILD_METHODS.md` - How to build native libraries
- `QUICKSTART.md` - General quick start

---

**One JAR. Any platform. Zero config.** ðŸŽ‰
