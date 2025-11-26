# LibPostal Zig + JNI - Quick Start

## Prerequisites
```bash
# Install Zig
brew install zig  # macOS
# or download from https://ziglang.org

# Install JDK and set JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home)  # macOS
export JAVA_HOME=/usr/lib/jvm/default-java   # Linux
```

## Build (3 commands)

```bash
# 1. Create JNI header links
mkdir -p src/jni/include
ln -sf $JAVA_HOME/include/jni.h src/jni/include/
ln -sf $JAVA_HOME/include/darwin/jni_md.h src/jni/include/  # macOS
# or for Linux: ln -sf $JAVA_HOME/include/linux/jni_md.h src/jni/include/

# 2. Build native libraries
zig build

# 3. Build Java
cd java
javac -d build/classes src/main/java/com/libpostal/*.java
jar cf libpostal.jar -C build/classes .
cd ..
```

**Or use the automated script:**
```bash
./build_jni.sh
```

## Run Example

```bash
cd examples
./run_example.sh
```

## Use in Your Code

```java
import com.libpostal.LibPostal;
import com.libpostal.AddressParserResponse;

// Initialize (once)
LibPostal.setup();
LibPostal.setupParser();

// Parse address
AddressParserResponse result = LibPostal.parseAddress(
    "123 Main St, New York, NY 10001", "us"
);

// Get results
for (int i = 0; i < result.components.length; i++) {
    System.out.println(result.labels[i] + ": " + result.components[i]);
}

// Cleanup
LibPostal.teardownParser();
LibPostal.teardown();
```

## Cross-Compile for All Platforms

```bash
zig build cross
```

Produces libraries for:
- Linux (x86_64, ARM64)
- macOS (Intel, Apple Silicon)
- Windows (x86_64, ARM64)

## Files You'll Use

```
zig-out/lib/
├── libpostal.dylib        # Core library
└── libpostal_jni.dylib    # JNI wrapper

java/
└── libpostal.jar          # Java classes
```

## Common Issues

**Build fails:** Check JAVA_HOME is set and JNI headers are linked

**Runtime UnsatisfiedLinkError:** Use `-Djava.library.path=zig-out/lib`

**Data not found:** Download libpostal data or use `LibPostal.setupDatadir("/path")`

## Next Steps

See full documentation:
- `BUILD_ZIG_JNI.md` - Detailed build guide
- `java/README.md` - Java API documentation
- `SUMMARY.md` - Complete overview
