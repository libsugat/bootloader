ASM := nasm
ASM_FLAGS := -f bin
BUILD_DIR := ./build
TARGET := $(BUILD_DIR)/disk.img

# Source files
BOOT_SRC := main.asm
STAGE2_SRC := stage2.asm

BOOT_BIN := $(BUILD_DIR)/boot.bin
STAGE2_BIN := $(BUILD_DIR)/stage2.bin

# --- Phony Targets ---
.PHONY: all run clean
    
run: all
	qemu-system-x86_64 -drive format=raw,file=$(TARGET)

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(TARGET): $(BOOT_BIN) $(STAGE2_BIN)
	@echo "[Creating disk image]: $@"
	@cat $^ > $(TARGET)

$(BUILD_DIR)/boot.bin: $(BOOT_SRC) | $(BUILD_DIR)
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

$(BUILD_DIR)/stage2.bin: $(STAGE2_SRC) | $(BUILD_DIR)
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

clean:
	@echo "Cleaning up build artifacts..."
	rm -rf $(BUILD_DIR)
