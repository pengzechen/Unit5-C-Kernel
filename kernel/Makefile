# Simple kernel build template.
#
# Usage:
#   make -C kernel build
#   make -C kernel qemu
#   make -C kernel clean

ARCH ?= aarch64

ifeq ($(ARCH),aarch64)
CROSS_COMPILE ?= aarch64-linux-musl-
else ifeq ($(ARCH),riscv64)
CROSS_COMPILE ?= riscv64-linux-musl-
else
CROSS_COMPILE ?=
endif

CC = $(CROSS_COMPILE)gcc
QEMU ?= qemu-system-aarch64

KERNEL_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR ?= $(KERNEL_DIR)/build
OBJ_DIR := $(BUILD_DIR)/obj
TARGET ?= $(BUILD_DIR)/kernel.elf
LDSCRIPT := $(KERNEL_DIR)/linker.ld

KERNEL_CPPFLAGS := -I$(KERNEL_DIR) -I$(KERNEL_DIR)/include
KERNEL_CFLAGS := -std=gnu11 -ffreestanding -fno-builtin -fno-stack-protector \
	-fno-pic -fno-pie -Wall -Wextra -O2 -g
KERNEL_ASFLAGS := -ffreestanding -g
KERNEL_LDFLAGS := -nostdlib -static -no-pie -Wl,--build-id=none -T $(LDSCRIPT)
QEMU_FLAGS ?= -machine virt -cpu cortex-a57 -m 128M -display none -serial mon:stdio

C_SRCS := $(shell find $(KERNEL_DIR) -path $(BUILD_DIR) -prune -o -name '*.c' -print)
S_SRCS := $(shell find $(KERNEL_DIR) -path $(BUILD_DIR) -prune -o \( -name '*.S' -o -name '*.s' \) -print)

OBJS := $(patsubst $(KERNEL_DIR)/%.c,$(OBJ_DIR)/%.o,$(C_SRCS))
OBJS += $(patsubst $(KERNEL_DIR)/%.S,$(OBJ_DIR)/%.o,$(filter %.S,$(S_SRCS)))
OBJS += $(patsubst $(KERNEL_DIR)/%.s,$(OBJ_DIR)/%.o,$(filter %.s,$(S_SRCS)))
DEPS := $(OBJS:.o=.d)

.PHONY: all build kernel qemu clean
.DELETE_ON_ERROR:

all: build
build: $(TARGET)
kernel: build
qemu: build
	$(QEMU) $(QEMU_FLAGS) -kernel $(TARGET)

ifeq ($(strip $(OBJS)),)
$(TARGET):
	$(error no source files found under $(KERNEL_DIR))
else
$(TARGET): $(OBJS) $(LDSCRIPT)
	@mkdir -p $(dir $@)
	$(CC) $(KERNEL_LDFLAGS) $(LDFLAGS) $(OBJS) -o $@
endif

$(OBJ_DIR)/%.o: $(KERNEL_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(KERNEL_CPPFLAGS) $(CPPFLAGS) $(KERNEL_CFLAGS) $(CFLAGS) -MMD -MP -c $< -o $@

$(OBJ_DIR)/%.o: $(KERNEL_DIR)/%.S
	@mkdir -p $(dir $@)
	$(CC) $(KERNEL_CPPFLAGS) $(CPPFLAGS) $(KERNEL_ASFLAGS) $(ASFLAGS) -MMD -MP -c $< -o $@

$(OBJ_DIR)/%.o: $(KERNEL_DIR)/%.s
	@mkdir -p $(dir $@)
	$(CC) $(KERNEL_CPPFLAGS) $(CPPFLAGS) $(KERNEL_ASFLAGS) $(ASFLAGS) -MMD -MP -c $< -o $@

clean:
	rm -rf $(BUILD_DIR)

-include $(DEPS)
