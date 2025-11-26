# Makefile for building LibPostal with Zig and JNI

.PHONY: all clean java native cross install test help

# Default target
all: native java

help:
	@echo "LibPostal Zig + JNI Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all        - Build native libraries and Java bindings"
	@echo "  native     - Build native libraries for current platform"
	@echo "  cross      - Cross-compile for all supported platforms"
	@echo "  java       - Compile Java classes and create JAR"
	@echo "  clean      - Remove build artifacts"
	@echo "  install    - Install libraries (requires sudo)"
	@echo "  test       - Run unit tests"
	@echo "  example    - Run Java example"
	@echo ""
	@echo "Usage:"
	@echo "  make all       # Build everything"
	@echo "  make cross     # Cross-compile for all platforms"
	@echo "  make test      # Run unit tests"
	@echo "  make example   # Run example program"

# Build native libraries
native:
	@echo "Building native libraries with Zig..."
	zig build
	@echo "✓ Native libraries built in zig-out/lib/"

# Cross-compile for all platforms
cross:
	@echo "Cross-compiling for all platforms..."
	zig build cross
	@echo "✓ Cross-compilation complete"

# Compile Java classes and create JAR
java:
	@echo "Compiling Java classes..."
	@mkdir -p java/build/classes
	javac -d java/build/classes java/src/main/java/com/libpostal/*.java
	@echo "Creating JAR..."
	cd java && jar cf libpostal.jar -C build/classes .
	@echo "✓ Java build complete: java/libpostal.jar"

# Run tests
test: all
	@echo "Running unit tests..."
	./run_tests.sh

# Run example
example: all
	@echo "Running example..."
	cd examples && ./run_example.sh

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf zig-out zig-cache
	rm -rf java/build
	rm -f java/libpostal.jar
	@echo "✓ Clean complete"

# Install (Unix-like systems)
install: native
	@echo "Installing libraries..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		sudo cp zig-out/lib/*.dylib /usr/local/lib/; \
	else \
		sudo cp zig-out/lib/*.so /usr/local/lib/; \
	fi
	sudo ldconfig 2>/dev/null || true
	@echo "✓ Installation complete"
