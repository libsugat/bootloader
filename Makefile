# Toolchain Configuration
ASM      := nasm
LD       := ld
OBJCOPY  := objcopy

ASM_FLAGS := -f elf32
LDFLAGS   := -m elf_i386

# Directories & Targets
BUILD_DIR           := build
BOOTSTRAP_DIR       := bootstrap
BOOTSTRAP_UTILS_DIR := $(BOOTSTRAP_DIR)/utils
TARGET              := $(BUILD_DIR)/disk.img

# Source & Object Mappings
BOOT_SRC      := $(BOOTSTRAP_DIR)/boot.asm
STAGE2_SRC    := stage2.asm
BS_UTILS_SRCS := $(wildcard $(BOOTSTRAP_UTILS_DIR)/*.asm)

BS_UTILS_OBJS := $(patsubst $(BOOTSTRAP_UTILS_DIR)/%.asm, $(BUILD_DIR)/utils/%.o, $(BS_UTILS_SRCS))
BS_OBJS       := $(strip $(BUILD_DIR)/boot.o $(BS_UTILS_OBJS))
STAGE2_OBJS   := $(BUILD_DIR)/stage2.o

# Build Artifacts
BS_ELF     := $(BUILD_DIR)/boot.elf
STAGE2_ELF := $(BUILD_DIR)/stage2.elf
BOOT_BIN   := $(BUILD_DIR)/boot.bin
STAGE2_BIN := $(BUILD_DIR)/stage2.bin

# --- Rules ---

all: $(BUILD_DIR) $(TARGET)

run: all
	@echo "[Running]: QEMU x86_64"
	qemu-system-x86_64 -drive format=raw,file=$(TARGET)

$(BUILD_DIR):
	@mkdir -p $@
	@mkdir -p $@/utils

# =========== Compilation ===========
$(BUILD_DIR)/utils/%.o: $(BOOTSTRAP_UTILS_DIR)/%.asm
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

$(BUILD_DIR)/boot.o: $(BOOT_SRC)
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

$(BUILD_DIR)/stage2.o: $(STAGE2_SRC)
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

# =========== Linking ==============
$(BS_ELF): $(BOOTSTRAP_DIR)/boot.ld $(BS_OBJS)
	@echo "[Linking Stage 1]"
	@$(LD) $(LDFLAGS) -T $(BOOTSTRAP_DIR)/boot.ld $(BS_OBJS) -o $(BS_ELF)

$(STAGE2_ELF): stage2.ld $(STAGE2_OBJS) $(BS_ELF)
	@echo "[Linking Stage 2]"
	@$(LD) $(LDFLAGS) -T stage2.ld $(STAGE2_OBJS) -R $(BS_ELF) -o $(STAGE2_ELF)

# =========== Binary Generation & Image Creation ===========
$(BOOT_BIN): $(BS_ELF) | $(BUILD_DIR)
	@$(OBJCOPY) -O binary $< $@

$(STAGE2_BIN): $(STAGE2_ELF) | $(BUILD_DIR)
	@$(OBJCOPY) -O binary $< $@

$(TARGET): $(BOOT_BIN) $(STAGE2_BIN)
	@echo "[Creating disk image]: $@"
	@cat $^ > $(TARGET)

# ============ Housekeeping & phony targets ================
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

.PHONY: all run clean
