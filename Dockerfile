# Avatar OS Kernel — Multi-architecture cross-compilation & QEMU emulation environment
# Adapted for CNB CI/CD and cloud-native development
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Use USTC mirror for faster apt downloads in China
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources

# Install build tools, QEMU emulators, and utilities in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ make python3 git binutils file wget xz-utils ca-certificates \
    e2fsprogs \
    qemu-system-arm \
    qemu-system-x86 \
    qemu-system-misc \
    && rm -rf /var/lib/apt/lists/*

# Download musl cross-compilation toolchains from musl.cc
# (Makefile expects aarch64-linux-musl-gcc / riscv64-linux-musl-gcc / x86_64-linux-musl-gcc)
RUN mkdir -p /opt/musl-cross && \
    for arch in aarch64 riscv64 x86_64; do \
        wget -q "https://musl.cc/${arch}-linux-musl-cross.tgz" -O - | tar -xz -C /opt/musl-cross; \
    done

# Add all musl toolchains to PATH
ENV PATH="/opt/musl-cross/aarch64-linux-musl-cross/bin:/opt/musl-cross/riscv64-linux-musl-cross/bin:/opt/musl-cross/x86_64-linux-musl-cross/bin:${PATH}"

# Symlink x86_64 toolchain to the hardcoded path expected by avatar-next/Makefile
RUN mkdir -p /home/ajax/SoftWare/compiler/x86_64-linux-musl-cross/bin && \
    for tool in gcc ar objcopy nm; do \
        ln -sf "/opt/musl-cross/x86_64-linux-musl-cross/bin/x86_64-linux-musl-${tool}" \
               "/home/ajax/SoftWare/compiler/x86_64-linux-musl-cross/bin/x86_64-linux-musl-${tool}"; \
    done

ENV DEBIAN_FRONTEND=

WORKDIR /workspace
