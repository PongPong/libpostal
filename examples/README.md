# LibPostal JNI Examples

This directory contains example programs demonstrating how to use the LibPostal JNI wrapper.

## Prerequisites

1. Build the native libraries and JAR:
   ```bash
   cd ..
   ./build_jni.sh
   ```

2. Make sure you have libpostal data downloaded (see main README.md)

## Java Examples

### Example 1: Basic Address Parsing

**File:** `java/com/libpostal/Example.java`

This example demonstrates:
- Initializing libpostal
- Parsing various address formats
- Expanding address abbreviations
- Using the map interface
- Proper cleanup

**Compile:**
```bash
javac -cp ../java/libpostal.jar -d build java/com/libpostal/Example.java
```

**Run:**
```bash
java -Djava.library.path=../zig-out/lib -cp build:../java/libpostal.jar com.libpostal.Example
```

Or use the provided script:
```bash
./run_example.sh
```

## Creating Your Own Examples

### 1. Create a new Java file

```java
package com.libpostal;

import com.libpostal.LibPostal;
import com.libpostal.AddressParserResponse;

public class MyExample {
    public static void main(String[] args) {
        // Initialize
        if (!LibPostal.setup() || !LibPostal.setupParser()) {
            System.err.println("Failed to initialize libpostal");
            System.exit(1);
        }
        
        // Your code here
        String address = "Your address here";
        AddressParserResponse result = LibPostal.parseAddress(address, "us");
        
        // Print results
        if (result != null) {
            for (int i = 0; i < result.components.length; i++) {
                System.out.println(result.labels[i] + ": " + result.components[i]);
            }
        }
        
        // Cleanup
        LibPostal.teardownParser();
        LibPostal.teardown();
    }
}
```

### 2. Compile

```bash
javac -cp ../java/libpostal.jar -d build java/com/libpostal/MyExample.java
```

### 3. Run

```bash
java -Djava.library.path=../zig-out/lib -cp build:../java/libpostal.jar com.libpostal.MyExample
```

## Example Categories

### Basic Usage
- `Example.java` - Complete demonstration of all features

### Additional Examples (TODO)
- Batch processing addresses from a file
- Integration with web services
- Custom data directory usage
- Multi-threaded address parsing

## Troubleshooting

**UnsatisfiedLinkError:**
- Make sure to use `-Djava.library.path=../zig-out/lib`
- Check that native libraries were built successfully

**Data not found:**
- Download libpostal data files
- Or use `LibPostal.setupDatadir("/path/to/data")`

**Class not found:**
- Verify the JAR is in classpath: `-cp ../java/libpostal.jar`
- Check that Java files were compiled to `build/` directory

## Structure

```
examples/
├── README.md           # This file
├── run_example.sh      # Helper script to run examples
├── build/              # Compiled classes (generated)
└── java/
    └── com/libpostal/
        ├── Example.java        # Main example
        └── MyExample.java      # Your custom examples
```

## API Quick Reference

```java
// Setup
boolean LibPostal.setup()
boolean LibPostal.setupParser()
void LibPostal.teardown()
void LibPostal.teardownParser()

// Parse address
AddressParserResponse parseAddress(String address)
AddressParserResponse parseAddress(String address, String country)
AddressParserResponse parseAddress(String address, String language, String country)

// Expand address
String[] expandAddress(String address)

// Response object
class AddressParserResponse {
    String[] components;
    String[] labels;
    Map<String, String> toMap()
}
```

## More Information

- Java API Documentation: `../java/README.md`
- Build Instructions: `../BUILD_ZIG_JNI.md`
- Quick Start Guide: `../QUICKSTART.md`
