# Makefile

ARMGNU ?= /usr/bin

# The directory in which source files are stored.
SOURCE = src

# The name of the output file to generate.
TARGET = $(PGM)
#TARGET = $1

# The intermediate directory for compiled object files.
BUILD = build

# The names of all object files that must be generated. Deduced from the 
# assembly code files in source.
OBJECTS = $(patsubst $(SOURCE)/%.s,$(BUILD)/%.o,$(wildcard $(SOURCE)/*.s))

# Rule to make everything.
all: $(TARGET)

 
# Rule to make the elf file.
$(PGM):  $(OBJECTS)
	$(ARMGNU)/ld  -o $(BUILD)/$(PGM) $(OBJECTS) -e main -T ~/scripts/linkerldarm.ld   --strip-all --print-map >map1.txt
 
# Rule to make the object files.
$(BUILD)/%.o: $(SOURCE)/%.s
	$(ARMGNU)/as   $< -o $@     -a >listing.txt
 



