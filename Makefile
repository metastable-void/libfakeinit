# libfakeinit for x86_64 Linux & SysV ABI
# Copyright (C) 2019 Menhera.org Developers

NASM = nasm

GCC = gcc
LD = ld
NASM = nasm
STRIP = strip
LDFLAGS = -static -nostdlib --no-define-common --strip-all --discard-all --no-ld-generated-unwind-info --gc-sections -z combreloc -z nocommon -z initfirst -z nodefaultlib -z interpose -z now -z nodelete -z noseparate-code -z norelro --sort-common --spare-dynamic-tags=0 --warn-common --hash-style sysv -Bsymbolic --orphan-handling=discard --no-export-dynamic
DEPS = Makefile
PAYLOAD_SOURCE = ./payload/main.asm
PAYLOAD_BIN = ./payload/main.bin
PAYLOAD_DEFLATED = ./payload/main.deflate
PAYLOAD_1 = ./payload/payload.1
PAYLOAD_2 = ./payload/payload.2
PAYLOAD_ENCODER_SOURCE = ./payload/encoder.c
PAYLOAD_ENCODER = ./payload/encoder
TARGET = ./libfakeinit.so.0
LOADER_OBJECT = ./wrapper/loader.o
LOADER_SOURCE = ./wrapper/loader.asm
RANDOM_0 = ./wrapper/random.0
RANDOM_1 = ./wrapper/random.1
RANDOM_2 = ./wrapper/random.2
RANDOM_3 = ./wrapper/random.3
RANDOM_4 = ./wrapper/random.4
RANDOM_5 = ./wrapper/random.5
RANDOM_6 = ./wrapper/random.6
RANDOM_7 = ./wrapper/random.7
RANDOM_8 = ./wrapper/random.8
RANDOM_9 = ./wrapper/random.9
RANDOM_10 = ./wrapper/random.10

all:	$(TARGET) $(DEPS)

$(PAYLOAD_BIN):	$(PAYLOAD_SOURCE)
	$(NASM) -o $(PAYLOAD_BIN) $(PAYLOAD_SOURCE)

$(PAYLOAD_DEFLATED):	$(PAYLOAD_BIN)
	gzip -9 --no-name < $(PAYLOAD_BIN) | tail -c +10 | head -c -8 > $(PAYLOAD_DEFLATED)

payloads:	$(PAYLOAD_ENCODER) $(PAYLOAD_BIN)
	$(PAYLOAD_ENCODER) < $(PAYLOAD_BIN) $(PAYLOAD_1) $(PAYLOAD_2)

$(PAYLOAD_ENCODER):	$(PAYLOAD_ENCODER_SOURCE)
	$(GCC) -o $(PAYLOAD_ENCODER) $(PAYLOAD_ENCODER_SOURCE)

$(TARGET):	$(LOADER_OBJECT)
	$(LD) -shared $(LDFLAGS) -o $(TARGET) $(LOADER_OBJECT)
	$(STRIP) -R .dynstr -R .dynsym -R .hash $(TARGET)

$(LOADER_OBJECT):	$(LOADER_SOURCE) payloads random
	$(NASM) -f elf64 -o $(LOADER_OBJECT) $(LOADER_SOURCE)

test:	$(TARGET)
	LD_DEBUG=all LD_PRELOAD=$(PWD)/$(TARGET) sh || true

random:	/dev/urandom
	dd if=/dev/urandom bs=83 count=1 of=$(RANDOM_0) 2>/dev/null
	dd if=/dev/urandom bs=77 count=1 of=$(RANDOM_1) 2>/dev/null
	dd if=/dev/urandom bs=47 count=1 of=$(RANDOM_2) 2>/dev/null
	dd if=/dev/urandom bs=55 count=1 of=$(RANDOM_3) 2>/dev/null
	dd if=/dev/urandom bs=11 count=1 of=$(RANDOM_4) 2>/dev/null
	dd if=/dev/urandom bs=25 count=1 of=$(RANDOM_5) 2>/dev/null
	dd if=/dev/urandom bs=23 count=1 of=$(RANDOM_6) 2>/dev/null
	dd if=/dev/urandom bs=31 count=1 of=$(RANDOM_7) 2>/dev/null
	dd if=/dev/urandom bs=22 count=1 of=$(RANDOM_8) 2>/dev/null
	dd if=/dev/urandom bs=19 count=1 of=$(RANDOM_9) 2>/dev/null
	dd if=/dev/urandom bs=17 count=1 of=$(RANDOM_10) 2>/dev/null

