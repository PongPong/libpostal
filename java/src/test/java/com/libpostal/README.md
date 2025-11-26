# LibPostal JNI Unit Tests

Comprehensive unit tests for the LibPostal JNI wrapper, designed to be safe and avoid panics/crashes.

## Test Files

### LibPostalTest.java
Tests the main JNI wrapper functionality:
- ✅ Library loading and initialization
- ✅ Address parsing with various inputs
- ✅ Null and empty input handling
- ✅ Special characters and Unicode
- ✅ International addresses
- ✅ Address expansion
- ✅ Thread safety (concurrent parsing)
- ✅ Edge cases (very long addresses, invalid country codes)

### AddressParserResponseTest.java
Tests the AddressParserResponse class (no native libraries required):
- ✅ Object creation and initialization
- ✅ toMap() conversion
- ✅ toString() formatting
- ✅ Null and empty array handling
- ✅ Mismatched array lengths
- ✅ Duplicate labels

## Running Tests

### Using the test script (recommended):
```bash
# From project root
./run_tests.sh
```

### Using Maven:
```bash
cd java
mvn test
```

### Manual compilation (without Maven):
```bash
cd java

# Download JUnit standalone JAR
wget https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/1.10.0/junit-platform-console-standalone-1.10.0.jar

# Compile tests
javac -cp "build/classes:junit-platform-console-standalone-1.10.0.jar" \
  -d build/test \
  src/test/java/com/libpostal/*.java

# Run tests
java -cp "build/classes:build/test:junit-platform-console-standalone-1.10.0.jar" \
  -Djava.library.path=../zig-out/lib \
  org.junit.platform.console.ConsoleLauncher \
  --scan-classpath build/test
```

## Test Design Principles

### 1. Safe & Robust
- **No panics**: Tests use `assertDoesNotThrow()` for potentially unsafe operations
- **Graceful degradation**: Tests skip if native libraries unavailable
- **Null safety**: Extensive testing of null inputs

### 2. Clear Feedback
- **Descriptive names**: Each test clearly states what it tests
- **Assumptions**: Tests skip with clear messages when prerequisites not met
- **Ordered execution**: Tests run in logical order (setup → basic → advanced)

### 3. Comprehensive Coverage
- **Positive cases**: Valid inputs produce expected outputs
- **Negative cases**: Invalid inputs handled gracefully
- **Edge cases**: Empty, null, very long, special characters
- **Concurrency**: Thread safety verification

## Test Categories

### Initialization Tests (Order 1-2)
```java
testLibraryLoading()    // Verify native libraries load
testSetup()             // Verify initialization succeeds
```

### Basic Functionality (Order 3-5)
```java
testParseSimpleAddress()       // Parse standard US address
testParseAddressNoCountry()    // Parse without country code
testParseNullAddress()         // Handle null gracefully
```

### Edge Cases (Order 6-9)
```java
testParseEmptyAddress()        // Empty string handling
testParseLongAddress()         // Very long input
testParseSpecialCharacters()   // Unicode & special chars
testParseInvalidCountryCode()  // Invalid country
```

### International Support (Order 10)
```java
testParseInternationalAddresses()  // Multiple countries/languages
```

### Response Object (Order 11)
```java
testToMapConversion()  // Verify map conversion
```

### Address Expansion (Order 12-13)
```java
testExpandAddress()      // Basic expansion
testExpandNullAddress()  // Null input handling
```

### Advanced (Order 14-16)
```java
testConcurrentParsing()       // Thread safety
testResponseToString()        // toString() method
testMultipleSequentialParses() // Multiple calls
```

## Handling Missing Dependencies

Tests are designed to run even if:
- Native libraries not built
- LibPostal data files not downloaded
- Running in CI environment without native dependencies

When dependencies are missing:
1. Tests detect the issue during `@BeforeAll`
2. Set `skipReason` with helpful message
3. Use `Assumptions.assumeTrue()` to skip tests
4. Report why tests were skipped

Example output when libraries missing:
```
LibPostal initialization failed - data files may be missing
Tests skipped: 14
```

## Expected Test Results

### All dependencies available:
```
Tests run: 16, Failures: 0, Errors: 0, Skipped: 0
✓ All tests passed!
```

### Native libraries not available:
```
Tests run: 16, Failures: 0, Errors: 0, Skipped: 14
⚠ Tests skipped (native libraries not found)
```

### AddressParserResponse tests (always run):
```
Tests run: 16, Failures: 0, Errors: 0, Skipped: 0
✓ All tests passed! (no native libraries needed)
```

## Adding New Tests

When adding tests for new functionality:

1. **Add to appropriate test class**:
   ```java
   @Test
   @Order(XX)
   @DisplayName("Clear description of what's being tested")
   public void testNewFeature() {
       Assumptions.assumeTrue(setupSuccessful, skipReason);
       
       assertDoesNotThrow(() -> {
           // Your test code
       }, "Should not crash");
   }
   ```

2. **Follow the patterns**:
   - Use `@Order` for logical sequence
   - Check assumptions for native-dependent tests
   - Use `assertDoesNotThrow()` for potentially unsafe ops
   - Test both positive and negative cases

3. **Run tests**:
   ```bash
   ./run_tests.sh
   ```

## Continuous Integration

Tests can be run in CI environments:

```yaml
# Example GitHub Actions
- name: Run tests
  run: |
    # Build native libraries
    ./build_jni.sh
    
    # Run tests
    ./run_tests.sh
```

Note: CI needs:
- Zig compiler installed
- JDK installed
- Maven installed (or use standalone JUnit)
- LibPostal data files (or tests will skip)

## Troubleshooting

### Tests are skipped
**Cause**: Native libraries not found or initialization failed

**Solution**:
```bash
# Build libraries
./build_jni.sh

# Check they exist
ls zig-out/lib/

# Try tests again
./run_tests.sh
```

### UnsatisfiedLinkError
**Cause**: Library path not set correctly

**Solution**:
```bash
# Check library path in test output
# Should see: -Djava.library.path=../zig-out/lib

# Or set manually
export LD_LIBRARY_PATH=./zig-out/lib:$LD_LIBRARY_PATH
cd java && mvn test
```

### Data files not found
**Cause**: LibPostal data not downloaded

**Solution**:
See main README.md for data download instructions, or use:
```java
LibPostal.setupDatadir("/path/to/libpostal/data");
```

### Compilation errors
**Cause**: JUnit dependencies not found

**Solution**:
```bash
cd java
mvn clean test  # Maven will download dependencies
```

## Test Coverage

Current coverage:
- ✅ Library initialization (2 tests)
- ✅ Address parsing (6 tests)
- ✅ Edge cases (4 tests)
- ✅ International support (1 test)
- ✅ Response object (1 test)
- ✅ Address expansion (2 tests)
- ✅ Concurrency (1 test)
- ✅ toString() (1 test)
- ✅ Sequential operations (1 test)
- ✅ AddressParserResponse class (16 tests)

Total: **35 tests**

## Contributing

When contributing tests:
1. Follow existing patterns
2. Add both positive and negative cases
3. Use `assertDoesNotThrow()` for potentially unsafe ops
4. Update this README if adding new test categories
5. Ensure tests pass with and without native libraries
