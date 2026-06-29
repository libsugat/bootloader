# Toolchain Configuration
ASM      := nasm
LD       := ld
OBJCOPY  := objcopy

# path to kernel to load
KERNEL ?= kernel

ASM_FLAGS := -f elf32
LDFLAGS   := -m elf_i386

# Directories & Targets
BUILD_DIR           := build
TARGET              := $(BUILD_DIR)/disk.img

BOOTSTRAP_DIR       := bootstrap
BOOTSTRAP_UTILS_DIR := $(BOOTSTRAP_DIR)/utils
STAGE2_DIR 			:= .
STAGE2_UTILS_DIR 	:= $(STAGE2_DIR)/utils

# Source & Object Mappings
BOOT_SRC      	  	:= $(BOOTSTRAP_DIR)/boot.asm
BS_UTILS_SRCS 		:= $(wildcard $(BOOTSTRAP_UTILS_DIR)/*.asm)
STAGE2_SRC    		:= $(STAGE2_DIR)/stage2.asm
STAGE2_UTILS_SRCS 	:= $(wildcard $(STAGE2_UTILS_DIR)/*.asm)

BS_UTILS_OBJS     := $(patsubst $(BOOTSTRAP_UTILS_DIR)/%.asm, $(BUILD_DIR)/bs_utils/%.o, $(BS_UTILS_SRCS))
BS_OBJS       	  := $(strip $(BUILD_DIR)/boot.o $(BS_UTILS_OBJS))
STAGE2_UTILS_OBJS := $(patsubst $(STAGE2_UTILS_DIR)/%.asm, $(BUILD_DIR)/utils/%.o, $(STAGE2_UTILS_SRCS))
STAGE2_OBJS   	  := $(strip $(BUILD_DIR)/stage2.o $(STAGE2_UTILS_OBJS))

# Build Artifacts
BS_ELF     := $(BUILD_DIR)/boot.elf
STAGE2_ELF := $(BUILD_DIR)/stage2.elf
BOOT_BIN   := $(BUILD_DIR)/boot.bin
STAGE2_BIN := $(BUILD_DIR)/stage2.bin

# --- Rules ---

all: $(BUILD_DIR) $(TARGET)

run: all
	@echo "[Running]: QEMU x86_64"
	qemu-system-x86_64 -drive format=raw,file=$(TARGET) -d cpu_reset,int -no-reboot -no-shutdown

$(BUILD_DIR):
	@mkdir -p $@
	@mkdir -p $@/utils
	@mkdir -p $@/bs_utils

# =========== Compilation ===========
$(BUILD_DIR)/bs_utils/%.o: $(BOOTSTRAP_UTILS_DIR)/%.asm
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

$(BUILD_DIR)/boot.o: $(BOOT_SRC)
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

$(BUILD_DIR)/utils/%.o: $(STAGE2_UTILS_DIR)/%.asm
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

$(BUILD_DIR)/stage2.o: $(STAGE2_SRC)
	@echo "[Assembling]: $< -> $@"
	@$(ASM) $(ASM_FLAGS) $< -o $@

# =========== Linking ==============
$(BS_ELF): $(BOOTSTRAP_DIR)/boot.ld $(BS_OBJS)
	@echo "[Linking Stage 1]"
	@$(LD) $(LDFLAGS) -T $(BOOTSTRAP_DIR)/boot.ld $(BS_OBJS) -o $(BS_ELF)

$(STAGE2_ELF): $(STAGE2_DIR)/stage2.ld $(STAGE2_OBJS) $(BS_ELF)
	@echo "[Linking Stage 2]"
	@$(LD) $(LDFLAGS) -T stage2.ld $(STAGE2_OBJS) -R $(BS_ELF) -o $(STAGE2_ELF)

# =========== Binary Generation & Image Creation ===========
$(BOOT_BIN): $(BS_ELF) | $(BUILD_DIR)
	@$(OBJCOPY) -O binary $< $@

$(STAGE2_BIN): $(STAGE2_ELF) | $(BUILD_DIR)
	@$(OBJCOPY) -O binary $< $@

$(KERNEL):
	@echo "❌ Error: 'kernel' binary not found in root directory!"
	@echo "Please build your ELF32 kernel and place it here as 'kernel' before making the disk image."
	@exit 1

$(TARGET): $(BOOT_BIN) $(STAGE2_BIN) $(KERNEL)
	@echo "[Creating disk image]: $@"
	@dd if=/dev/zero of=$(TARGET) bs=512 count=4096
	@echo "Writing MBR..."
	@dd if=$(BOOT_BIN) of=$(TARGET) bs=512 count=1 conv=notrunc
	@echo "Writing STAGE 2..."
	@dd if=$(STAGE2_BIN) of=$(TARGET) bs=512 seek=1 conv=notrunc
	@echo "Writing Kernel..."
	@dd if=$(KERNEL) of=$(TARGET) bs=512 seek=4 conv=notrunc
	@sync

# ============ Housekeeping & phony targets ================
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

.PHONY: all run clean
