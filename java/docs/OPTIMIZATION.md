# LibPostal Build Optimization Guide

Comprehensive guide to optimizing LibPostal native libraries for size and performance.

## Current State

### Build Methods

| Method | Status | Optimization | Fat JAR Ready |
|--------|--------|--------------|---------------|
| **Autotools** | ✅ Working | Default (-O2) | ✅ Yes (current) |
| **Zig** | ❌ Broken | Would be optimal | ❌ No |

### Current Fat JAR

The fat JAR currently includes:
- ❌ Autotools-built libraries (default optimization)
- ❌ Debug symbols included
- ❌ Not stripped
- ❌ Not compressed
- ❌ ~10-20MB per platform

**Potential: 30-70% size reduction possible!**

## Optimization Strategies

### Strategy 1: Optimize Autotools Build (Quick Win)

Update `build_jni_simple.sh` to use optimized flags:

```bash
# Add to configure
CFLAGS="-Os -flto -ffunction-sections -fdata-sections" \
LDFLAGS="-Wl,--gc-sections" \
./configure --prefix=/usr/local

# For macOS
CFLAGS="-Os -flto -ffunction-sections -fdata-sections" \
LDFLAGS="-Wl,-dead_strip" \
./configure --prefix=/usr/local
```

**Benefits:**
- `-Os` - Optimize for size
- `-flto` - Link-time optimization
- `-ffunction-sections` - Separate functions for stripping
- `-Wl,--gc-sections` - Remove unused code (Linux)
- `-Wl,-dead_strip` - Remove unused code (macOS)

**Expected: 20-30% size reduction**

### Strategy 2: Strip Debug Symbols (Easy)

Add to `build_fatjar.sh`:

```bash
# After building, strip libraries
if [[ $platform == linux-* ]]; then
    strip --strip-all lib/$platform/*.so
elif [[ $platform == macos-* ]]; then
    strip -x lib/$platform/*.dylib
elif [[ $platform == windows-* ]]; then
    strip lib/$platform/*.dll
fi
```

**Expected: 30-40% size reduction**

### Strategy 3: UPX Compression (Advanced)

Compress libraries with UPX:

```bash
# Install UPX
brew install upx  # macOS
apt-get install upx  # Linux

# Compress
upx --best --lzma lib/**/*.{so,dylib,dll}
```

**Expected: 40-60% size reduction**  
**⚠️ Warning: Slower startup, antivirus may flag**

### Strategy 4: Fix Zig Build (Best, Most Work)

Zig provides superior optimization but needs fixes:

**Problems to solve:**
1. Missing snappy dependency
2. Missing generated headers (from autotools configure)
3. Need to vendor all dependencies

**Benefits if working:**
- Cross-compilation (build all platforms on one machine)
- Superior LTO and optimization
- Smaller binaries
- Faster builds

## Rust Guide Relevance

The [min-sized-rust guide](https://github.com/johnthagen/min-sized-rust) is **highly relevant**! 

Many techniques apply to C/C++ builds:

### Applicable Techniques

| Rust Technique | C Equivalent | How to Use |
|----------------|--------------|------------|
| `opt-level = "z"` | `-Os` | Size optimization |
| `lto = true` | `-flto` | Link-time optimization |
| `strip = true` | `strip` command | Remove debug symbols |
| `panic = "abort"` | N/A | C doesn't have panic |
| `codegen-units = 1` | `-flto` | Single compilation unit |
| UPX compression | UPX | Same tool! |

### Not Applicable

- ❌ Cargo features (C has no equivalent)
- ❌ Rust-specific optimizations
- ❌ std vs no_std (C always uses libc)

## Recommended Optimization Levels

### Development Build
```bash
# Fast builds, easy debugging
CFLAGS="-O0 -g"
```

### Production Build  
```bash
# Balanced size and speed
CFLAGS="-O2 -DNDEBUG"
```

### Size-Optimized Build
```bash
# Smallest size (current fat JAR target)
CFLAGS="-Os -flto -ffunction-sections -fdata-sections -DNDEBUG"
LDFLAGS="-Wl,--gc-sections -Wl,--strip-all"

# Then:
strip --strip-all *.so
upx --best *.so  # optional
```

### Performance Build
```bash
# Fastest execution
CFLAGS="-O3 -march=native -flto"
# Don't use for fat JAR (not portable)
```

## Implementation Plan

### Phase 1: Low-Hanging Fruit (Do This Now!)

Update `build_jni_simple.sh`:

```bash
# Before configure
export CFLAGS="-Os -flto -ffunction-sections -fdata-sections -DNDEBUG"
export LDFLAGS="-Wl,--gc-sections"

# Add strip step after build
strip --strip-all lib/*.so 2>/dev/null || true
strip -x lib/*.dylib 2>/dev/null || true
```

**Effort: 10 minutes**  
**Gain: 30-50% size reduction**

### Phase 2: Compression (Optional)

Add UPX step to `build_fatjar.sh`:

```bash
# After organizing libraries, before JAR creation
if command -v upx &> /dev/null; then
    echo "Compressing libraries with UPX..."
    find "$NATIVE_DIR" -name "*.so" -o -name "*.dylib" -o -name "*.dll" | \
        xargs upx --best --lzma 2>/dev/null || true
fi
```

**Effort: 5 minutes**  
**Gain: Additional 40-60% on already-stripped libs**  
**Trade-off: Slower startup**

### Phase 3: Fix Zig Build (Future)

To make Zig build work:

1. **Vendor snappy** - Include source in project
2. **Pre-run configure** - Generate config.h
3. **Add all dependencies** to build.zig
4. **Test cross-compilation**

**Effort: Several hours**  
**Gain: Build on one machine for all platforms**

## Size Comparison

Estimated sizes for **single platform** (e.g., Linux x86_64):

| Optimization | libpostal.so | libpostal_jni.so | Total |
|--------------|--------------|------------------|-------|
| Default | ~8MB | ~200KB | ~8.2MB |
| -Os | ~6MB | ~150KB | ~6.1MB |
| -Os + strip | ~4MB | ~100KB | ~4.1MB |
| -Os + strip + UPX | ~2MB | ~50KB | ~2.0MB |

### Fat JAR Sizes

All 6 platforms:

| Optimization | Size | Build Time | Startup |
|--------------|------|------------|---------|
| Default | ~50MB | Fast | Fast |
| -Os | ~37MB | Medium | Fast |
| -Os + strip | ~25MB | Medium | Fast |
| -Os + strip + UPX | ~12MB | Slow | Medium |

**Recommendation: -Os + strip (25MB, fast startup)**

## Optimized Build Scripts

### build_jni_optimized.sh

```bash
#!/bin/bash
set -e

echo "=== Optimized LibPostal JNI Build ==="

# Optimization flags
export CFLAGS="-Os -flto -ffunction-sections -fdata-sections -DNDEBUG"

# Platform-specific linker flags
OS=$(uname -s)
if [ "$OS" = "Darwin" ]; then
    export LDFLAGS="-Wl,-dead_strip"
else
    export LDFLAGS="-Wl,--gc-sections -Wl,--strip-all"
fi

# Build with autotools
./bootstrap.sh
./configure --prefix=/usr/local
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Build JNI wrapper
# ... (rest of build_jni_simple.sh)

# Strip symbols
echo "Stripping debug symbols..."
if [ "$OS" = "Darwin" ]; then
    strip -x lib/*.dylib
else
    strip --strip-all lib/*.so
fi

# Optional: UPX compression
if command -v upx &> /dev/null; then
    echo "Compressing with UPX..."
    upx --best lib/*
fi

echo "✓ Optimized build complete!"
```

### build_fatjar_optimized.sh

```bash
#!/bin/bash
set -e

# In the copy_platform_libs function, add:
optimize_libraries() {
    local dest_dir=$1
    
    # Strip
    find "$dest_dir" -name "*.so" -exec strip --strip-all {} \; 2>/dev/null || true
    find "$dest_dir" -name "*.dylib" -exec strip -x {} \; 2>/dev/null || true
    find "$dest_dir" -name "*.dll" -exec strip {} \; 2>/dev/null || true
    
    # Optional: UPX
    if command -v upx &> /dev/null && [ "$USE_UPX" = "1" ]; then
        find "$dest_dir" \( -name "*.so" -o -name "*.dylib" -o -name "*.dll" \) \
            -exec upx --best {} \; 2>/dev/null || true
    fi
}

# Call after copying each platform
optimize_libraries "$NATIVE_DIR/$platform"
```

## Build Profiles

Create different profiles for different use cases:

### Profile: Development
```bash
export BUILD_PROFILE="dev"
export CFLAGS="-O0 -g"
# Fast build, easy debug
```

### Profile: Production
```bash
export BUILD_PROFILE="prod"
export CFLAGS="-O2 -DNDEBUG"
# Balanced
```

### Profile: Size
```bash
export BUILD_PROFILE="size"
export CFLAGS="-Os -flto -ffunction-sections -fdata-sections -DNDEBUG"
export USE_STRIP=1
# Smallest (recommended for fat JAR)
```

### Profile: Performance
```bash
export BUILD_PROFILE="perf"
export CFLAGS="-O3 -flto -march=native"
# Fastest (not portable)
```

## Zig-Specific Optimization

If/when Zig build is fixed:

```zig
// In build.zig
const optimize = b.option(
    std.builtin.OptimizeMode,
    "optimize",
    "Optimization mode"
) orelse .ReleaseSmall;  // Size-optimized by default

// Add strip option
const strip = b.option(bool, "strip", "Strip debug symbols") orelse true;

const lib = b.addLibrary(.{
    .name = "postal",
    .optimize = optimize,
    .strip = strip,
    // ...
});
```

Build commands:
```bash
# Size-optimized
zig build -Doptimize=ReleaseSmall -Dstrip=true

# Performance
zig build -Doptimize=ReleaseFast

# Debug
zig build -Doptimize=Debug
```

## Benchmarking

Test different optimization levels:

```bash
# Size
ls -lh lib/*.so

# Startup time
time java -jar libpostal-fatjar.jar

# Parse performance
java -jar libpostal-fatjar.jar benchmark
```

## Recommendations

### For Fat JAR Distribution

1. ✅ **Use `-Os` optimization** - Good balance
2. ✅ **Strip debug symbols** - Essential
3. ⚠️ **UPX compression** - Optional, test first
4. ❌ **Don't use `-march=native`** - Not portable
5. ✅ **Enable LTO** - Good size and speed wins

### For System Installation

1. ✅ **Use `-O2` or `-O3`** - Performance matters
2. ⚠️ **Keep debug symbols** - Helps debugging
3. ❌ **No UPX** - Unnecessary overhead
4. ✅ **Use `-march=native`** - Performance boost

## Action Items

### Immediate (Do Now)
- [ ] Create `build_jni_optimized.sh` with `-Os` and strip
- [ ] Update `build_fatjar.sh` to strip libraries
- [ ] Test size reduction
- [ ] Document new build commands

### Short Term (This Week)
- [ ] Add UPX compression as optional step
- [ ] Create build profiles (dev/prod/size)
- [ ] Benchmark different optimization levels
- [ ] Update documentation

### Long Term (Future)
- [ ] Fix Zig build system
- [ ] Vendor snappy and dependencies
- [ ] Enable Zig cross-compilation
- [ ] Automate multi-platform builds

## Summary

| Goal | Method | Expected Result |
|------|--------|-----------------|
| **Quick Win** | `-Os` + strip | 30-50% smaller |
| **Aggressive** | + UPX | 60-70% smaller |
| **Best** | Fix Zig + optimize | 70%+ smaller + cross-compile |

**Recommended: Start with Phase 1 (`-Os` + strip) - Easy win with minimal risk!**

---

**Inspired by: [min-sized-rust](https://github.com/johnthagen/min-sized-rust)** ✨
