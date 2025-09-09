# Makefile for Bose QC35 Controller - macOS Apple Silicon

CC = clang
TARGET = based-connect
SOURCE = based-connect.m

# Frameworks and libraries
FRAMEWORKS = -framework Cocoa -framework IOBluetooth
LIBS =

# Compiler flags
CFLAGS = -Wall -Wextra -std=c11
OBJCFLAGS = -fobjc-arc -fmodules

# Architecture - support both Intel and Apple Silicon
ARCH_FLAGS = -arch arm64 -arch x86_64

# Deployment target for compatibility
DEPLOYMENT_TARGET = -mmacosx-version-min=10.15

# Combine all flags
ALL_FLAGS = $(CFLAGS) $(OBJCFLAGS) $(ARCH_FLAGS) $(DEPLOYMENT_TARGET) $(FRAMEWORKS)

# Default target
all: $(TARGET)

# Build the main executable
$(TARGET): $(SOURCE)
	$(CC) $(ALL_FLAGS) -o $(TARGET) $(SOURCE)
	@echo "Build complete. Run with ./$(TARGET) --help"

# Clean build artifacts
clean:
	rm -f $(TARGET)
	@echo "Clean complete"

# Install to /usr/local/bin (requires sudo)
install: $(TARGET)
	sudo cp $(TARGET) /usr/local/bin/
	@echo "Installed to /usr/local/bin/$(TARGET)"

# Uninstall from /usr/local/bin
uninstall:
	sudo rm -f /usr/local/bin/$(TARGET)
	@echo "Uninstalled from /usr/local/bin"

# Development build (single architecture, debug info)
debug: ARCH_FLAGS = -arch arm64
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

# Show help
help:
	@echo "Available targets:"
	@echo "  all       - Build the controller (default)"
	@echo "  clean     - Remove build artifacts"
	@echo "  install   - Install to /usr/local/bin (requires sudo)"
	@echo "  uninstall - Remove from /usr/local/bin (requires sudo)"
	@echo "  debug     - Build with debug info (arm64 only)"
	@echo "  help      - Show this help"

.PHONY: all clean install uninstall debug help
