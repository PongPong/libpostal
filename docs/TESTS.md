# LibPostal JNI Unit Tests

Comprehensive unit tests for the LibPostal JNI wrapper with a focus on safety and robustness.

## Overview

**Total Tests: 35** (589 lines of test code)
- **19 tests** for LibPostal JNI wrapper
- **16 tests** for AddressParserResponse class

### Key Features

bœ… **No Panics** - All tests use `assertDoesNotThrow()` for potentially unsafe operations  
bœ… **Graceful Degradation** - Tests skip with clear messages when libraries unavailable  
bœ… **Null Safety** - Extensive testing of null and empty inputs  
bœ… **Thread Safety** - Concurrent parsing tests with 5 threads  
bœ… **CI/CD Ready** - Works in automated environments  

## Running Tests

### Quick Start

```bash
# From project root
./run_tests.sh
```

### Using Make

```bash
make test
```

### Using Maven

```bash
cd java
mvn test
```

## Test Files

```
java/src/test/java/com/libpostal/
b”œâ”€b”€ LibPostalTest.java               # JNI wrapper tests (19 tests)
b”œâ”€â”€ AddressParserResponseTest.java   # Response class tests (16 tests)
b””â”€â”€ README.md                        # Detailed documentation
```

## Test Coverage

### LibPostalTest (19 tests)

#### Initialization (2 tests)
- `testLibraryLoading()` - Verify native libraries load
- `testSetup()` - Verify LibPostal initialization

#### Basic Functionality (3 tests)
- `testParseSimpleAddress()` - Parse standard US address
- `testParseAddressNoCountry()` - Parse without country code
- `testParseNullAddress()` - Handle null input gracefully

#### Edge Cases (4 tests)
- `testParseEmptyAddress()` - Empty string handling
- `testParseLongAddress()` - Very long input (10,000+ chars)
- `testParseSpecialCharacters()` - Unicode & special characters
- `testParseInvalidCountryCode()` - Invalid country handling

#### International Support (1 test)
- `testParseInternationalAddresses()` - UK, US, FR, JP addresses

#### Response Features (1 test)
- `testToMapConversion()` - Verify map conversion

#### Address Expansion (2 tests)
- `testExpandAddress()` - Basic expansion
- `testExpandNullAddress()` - Null expansion handling

#### Advanced (3 tests)
- `testConcurrentParsing()` - Thread safety (5 threads Ã— 10 iterations)
- `testResponseToString()` - toString() method
- `testMultipleSequentialParses()` - Sequential operations

### AddressParserResponseTest (16 tests)

#### Construction (4 tests)
- Null arrays
- Empty arrays  
- Valid data
- Default constructor

#### toMap() Method (7 tests)
- Null arrays â†’ empty map
- Empty arrays â†’ empty map
- Valid data â†’ correct map
- Mismatched lengths
- Null elements
- Duplicate labels
- New map each time

#### toString() Method (4 tests)
- Null arrays
- Empty arrays
- Valid data
- Null elements

#### Mutation (1 test)
- Arrays not copied (reference retained)

## Safety Design

### No Panics Guaranteed

Every test that could potentially crash uses `assertDoesNotThrow()`:

```java
assertDoesNotThrow(() -> {
    AddressParserResponse response = LibPostal.parseAddress(null, "us");
    // Validate response if not null
}, "Should handle null address without crashing");
```

### Graceful Skipping

Tests check prerequisites and skip with clear messages:

```java
@BeforeAll
public void setupLibrary() {
    try {
        libraryLoaded = true;
        setupSuccessful = LibPostal.setup() && LibPostal.setupParser();
    } catch (Exception e) {
        skipReason = "Reason: " + e.getMessage();
    }
}

@Test
public void testParsing() {
    Assumptions.assumeTrue(setupSuccessful, skipReason);
    // Test code...
}
```

### Null Safety

Extensive testing of null inputs:
- Null addresses
- Null country codes
- Null arrays in response
- Null elements in arrays

### Thread Safety

Concurrent parsing test with 5 threads:

```java
Thread[] threads = new Thread[5];
for (int i = 0; i < threads.length; i++) {
    threads[i] = new Thread(() -> {
        for (int j = 0; j < 10; j++) {
            LibPostal.parseAddress(address, "us");
        }
    });
}
// Start all threads and join with timeout
```

## Expected Results

### All Dependencies Available

```
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.libpostal.AddressParserResponseTest
[INFO] Tests run: 16, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.libpostal.LibPostalTest
[INFO] Tests run: 19, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 35, Failures: 0, Errors: 0, Skipped: 0
[INFO]
bœ“ All tests passed!
```

### Native Libraries Missing

```
[INFO] Running com.libpostal.AddressParserResponseTest
[INFO] Tests run: 16, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.libpostal.LibPostalTest
[INFO] Tests run: 19, Failures: 0, Errors: 0, Skipped: 17
[INFO]
bš  Some tests skipped (native libraries not found)
```

Note: AddressParserResponse tests always run (no native library needed).

## What Gets Tested

### Input Validation
- âœ… Null addresses
- âœ… Empty strings
- âœ… Very long inputs (10,000+ characters)
- âœ… Special characters (â‚¬, Ã¼, Ã±, etc.)
- âœ… Unicode (Japanese, Chinese, Arabic)
- âœ… Invalid country codes

### Functionality
- âœ… Basic address parsing
- âœ… International addresses (US, UK, FR, JP)
- âœ… Address expansion
- âœ… Map conversion
- âœ… String formatting

### Safety & Robustness
- âœ… Thread safety (concurrent parsing)
- âœ… Sequential operations (multiple parses)
- âœ… Memory handling (no leaks in tests)
- âœ… Null pointer safety
- âœ… Edge case handling

### Response Object
- âœ… Construction with various inputs
- âœ… Null/empty array handling
- âœ… Mismatched array lengths
- âœ… Duplicate labels
- âœ… Array mutation behavior

## CI/CD Integration

Tests are designed for automated environments:

### GitHub Actions Example

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        
    - name: Setup Zig
      uses: goto-bus-stop/setup-zig@v2
      with:
        version: 0.15.1
        
    - name: Build
      run: ./build_jni.sh
      
    - name: Run Tests
      run: ./run_tests.sh
```

### Features for CI
- Exit codes properly set
- Clear output messages
- Tests skip gracefully if libraries missing
- No interactive prompts
- Timeout protection (5s per concurrent test)

## Troubleshooting

### Tests Skipped

**Problem**: Most tests show "Skipped"

**Solutions**:
1. Build native libraries: `./build_jni.sh`
2. Check libraries exist: `ls zig-out/lib/`
3. Verify JAVA_HOME: `echo $JAVA_HOME`

### UnsatisfiedLinkError

**Problem**: `java.lang.UnsatisfiedLinkError: no postal in java.library.path`

**Solutions**:
```bash
# Check library path
./run_tests.sh  # Script sets path automatically

# Or set manually
export LD_LIBRARY_PATH=./zig-out/lib:$LD_LIBRARY_PATH
cd java && mvn test
```

### Data Files Missing

**Problem**: Tests skip with "initialization failed"

**Solution**: Download LibPostal data (see main README.md) or tests will skip gracefully.

### Maven Not Found

**Problem**: `mvn: command not found`

**Solution**:
```bash
# Install Maven
brew install maven  # macOS
apt-get install maven  # Ubuntu

# Or use manual test compilation (see test README)
```

## Adding New Tests

When adding tests:

1. **Follow the pattern**:
   ```java
   @Test
   @Order(XX)
   @DisplayName("Clear description")
   public void testNewFeature() {
       Assumptions.assumeTrue(setupSuccessful, skipReason);
       
       assertDoesNotThrow(() -> {
           // Test code
       }, "Should not crash");
   }
   ```

2. **Test both paths**:
   - Positive case (valid input)
   - Negative case (invalid input)

3. **Use safety wrappers**:
   - `assertDoesNotThrow()` for potentially unsafe ops
   - `Assumptions.assumeTrue()` for prerequisites
   - Null checks before assertions

4. **Run tests**:
   ```bash
   ./run_tests.sh
   ```

## Test Statistics

- **Total Tests**: 35
- **Test Code**: 589 lines
- **Coverage**: 
  - Library loading & setup
  - Address parsing (all variations)
  - Response object (all methods)
  - Edge cases & error conditions
  - Thread safety
  - Sequential operations

## Documentation

Detailed documentation in:
- `java/src/test/java/com/libpostal/README.md` - Full test guide
- `TESTS.md` - This file (overview)
- Test javadocs - In-code documentation

## Contributing

When contributing:
1. Add tests for new features
2. Follow existing patterns
3. Ensure tests pass with/without native libraries
4. Update documentation
5. Run full test suite: `./run_tests.sh`

---

**35 tests ensuring LibPostal JNI wrapper is safe, robust, and reliable!** bœ…
