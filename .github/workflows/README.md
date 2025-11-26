# GitHub Actions Workflows

This directory contains CI/CD workflows for LibPostal.

## Workflows

### 1. Test (`test.yml`)

**Trigger:** Push, Pull Request  
**Purpose:** Run tests on Linux and macOS

**Jobs:**
- Build and test on Ubuntu
- Build and test on macOS

### 2. Build Native Libraries (`build-native.yml`)

**Trigger:** Push to master/main, Tags, Manual  
**Purpose:** Build optimized native libraries for all platforms

**Platforms:**
- Linux x86_64
- Linux ARM64 (aarch64)
- macOS x86_64 (Intel)
- macOS aarch64 (Apple Silicon)
- Windows x86_64

**Outputs:**
- `native-linux-x86_64` artifact
- `native-linux-aarch64` artifact
- `native-macos-x86_64` artifact
- `native-macos-aarch64` artifact
- `native-windows-x86_64` artifact

**Features:**
- Size-optimized builds (`-Os` + LTO)
- Debug symbols stripped
- Cross-compilation for ARM64

### 3. Build Fat JAR (`build-fatjar.yml`)

**Trigger:** After native build completes, Tags, Manual  
**Purpose:** Create cross-platform fat JAR

**Process:**
1. Downloads native library artifacts
2. Organizes into platform directories
3. Compiles Java classes
4. Packages everything into fat JAR
5. Creates checksums
6. Creates GitHub release (if triggered by tag)

**Outputs:**
- `libpostal-fatjar.jar` artifact
- `libpostal-fatjar.jar.sha256` checksum

**Features:**
- Automatic platform detection
- Size analysis
- Release notes generation

### 4. Release (`release.yml`)

**Trigger:** Version tags (`v*.*.*`), Manual  
**Purpose:** Complete release build with all artifacts

**Process:**
1. Build native libraries for all platforms
2. Create platform-specific tarballs
3. Build fat JAR with all libraries
4. Create GitHub release with:
   - Fat JAR
   - Platform-specific tarballs
   - Checksums
   - Release notes

**Outputs:**
- `libpostal-fatjar.jar` - Cross-platform JAR
- `libpostal-linux-x86_64.tar.gz` - Linux x86_64 libraries
- `libpostal-linux-aarch64.tar.gz` - Linux ARM64 libraries
- `libpostal-macos-x86_64.tar.gz` - macOS Intel libraries
- `libpostal-macos-aarch64.tar.gz` - macOS Apple Silicon libraries
- SHA256 checksums for all files

## Usage

### Automatic Workflows

**On every push to master/main:**
1. `test.yml` runs tests
2. `build-native.yml` builds native libraries
3. `build-fatjar.yml` creates fat JAR (triggered by native build completion)

**On tag push (e.g., `v1.0.0`):**
1. `release.yml` runs complete release build
2. Creates GitHub release with all artifacts

### Manual Workflows

**Build Native Libraries:**
```bash
# Go to Actions tab → Build Native Libraries → Run workflow
```

**Build Fat JAR:**
```bash
# Go to Actions tab → Build Fat JAR → Run workflow
```

**Create Release:**
```bash
# Create and push tag
git tag v1.0.0
git push origin v1.0.0

# Or use Actions tab → Release → Run workflow
```

## Workflow Dependencies

```
Push to master/main
  ↓
test.yml (runs tests)
  ↓
build-native.yml (builds libraries)
  ↓
build-fatjar.yml (creates fat JAR)

Push tag (v*.*.*)
  ↓
release.yml (complete release)
  ├─ build natives
  ├─ create tarballs
  ├─ build fat JAR
  └─ create GitHub release
```

## Artifacts

### Native Artifacts (7 days retention)

| Artifact Name | Contents | Size |
|---------------|----------|------|
| `native-linux-x86_64` | libpostal.so, libpostal_jni.so | ~4MB |
| `native-linux-aarch64` | libpostal.so, libpostal_jni.so | ~4MB |
| `native-macos-x86_64` | libpostal.dylib, libpostal_jni.dylib | ~4MB |
| `native-macos-aarch64` | libpostal.dylib, libpostal_jni.dylib | ~3MB |
| `native-windows-x86_64` | postal.dll, postal_jni.dll | ~5MB |

### Fat JAR Artifact (30 days retention)

| Artifact Name | Contents | Size |
|---------------|----------|------|
| `libpostal-fatjar` | libpostal-fatjar.jar, checksums | ~25MB |

## Environment Variables

Workflows use these environment variables:

- `JAVA_HOME` - JDK installation path
- `CFLAGS` - Compiler flags for optimization
- `LDFLAGS` - Linker flags for optimization
- `LIBPOSTAL_DATA_DIR` - LibPostal data directory

## Optimization Settings

All native builds use:
```bash
CFLAGS="-Os -flto -ffunction-sections -fdata-sections -DNDEBUG"
LDFLAGS="-Wl,--gc-sections"  # Linux
LDFLAGS="-Wl,-dead_strip"    # macOS
```

Plus:
- Debug symbols stripped with `strip`
- Size-optimized builds (~50% smaller)

## Platform-Specific Notes

### Linux ARM64
- Uses QEMU for cross-compilation
- Builds in `arm64v8/ubuntu:22.04` container

### macOS
- Intel builds use `macos-13`
- Apple Silicon builds use `macos-14`

### Windows
- Uses MSYS2 environment
- MinGW-w64 toolchain

## Troubleshooting

### Native build fails

**Check:**
1. Dependencies installed correctly
2. JAVA_HOME is set
3. Autotools version compatible

**Solution:**
- View workflow logs
- Run locally: `./scripts/build/build_jni_optimized.sh`

### Fat JAR build fails

**Check:**
1. Native artifacts available
2. Platform directories correct
3. Java classes compile

**Solution:**
- Ensure native workflow completed first
- Check artifact names match expected pattern

### Release creation fails

**Check:**
1. Tag format is correct (`v*.*.*`)
2. Permissions are set (needs `contents: write`)
3. All platforms built successfully

**Solution:**
- Use correct tag format
- Check repository settings → Actions → Workflow permissions

## Local Testing

Test workflows locally with [act](https://github.com/nektos/act):

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Test native build
act -j build-linux-x86_64

# Test fat JAR build
act -j build-fatjar

# Test complete release
act -j create-release
```

## Monitoring

View workflow status:
- **Actions tab** - All workflow runs
- **Badges** - Add to README.md:
  ```markdown
  ![Build Native](https://github.com/USER/REPO/actions/workflows/build-native.yml/badge.svg)
  ![Build Fat JAR](https://github.com/USER/REPO/actions/workflows/build-fatjar.yml/badge.svg)
  ```

## Cost Optimization

**Minutes used per workflow:**
- `test.yml`: ~10 minutes
- `build-native.yml`: ~30 minutes (all platforms)
- `build-fatjar.yml`: ~5 minutes
- `release.yml`: ~35 minutes (complete)

**Tips:**
- Native artifacts cached for 7 days
- Fat JAR artifacts cached for 30 days
- Use manual triggers for testing
- Concurrent runs limited by matrix

## Security

**Artifacts contain:**
- ✅ Compiled binaries only
- ✅ No source code
- ✅ No secrets
- ✅ Public checksums

**Permissions:**
- Read: All workflows
- Write: Release workflow only (for creating releases)

## Future Improvements

- [ ] Add Windows ARM64 support
- [ ] Add Docker image builds
- [ ] Add Maven Central deployment
- [ ] Add benchmark tests
- [ ] Add security scanning
- [ ] Add SBOM generation

## Questions?

See main documentation:
- [java/docs/FATJAR.md](../../java/docs/FATJAR.md) - Fat JAR guide
- [java/docs/BUILD_METHODS.md](../../java/docs/BUILD_METHODS.md) - Build methods
- [java/docs/OPTIMIZATION.md](../../java/docs/OPTIMIZATION.md) - Optimization guide
