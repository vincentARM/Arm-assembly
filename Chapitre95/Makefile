# Makefile  Lancer par make PGM=nomexecutable
# répertoire des utilitaires
ARMGNU ?= /usr/bin/

# répertoire des sources
SOURCE = src


# répertoire des objets et de l'executable final
BUILD = build

# nom des objets déduits des noms des sources du répertoire SOURCE
OBJECTS = $(patsubst $(SOURCE)/%.s,$(BUILD)/%.o,$(wildcard $(SOURCE)/*.s))

# Régle pour générer l'executable
all: $(PGM)

 
# Régle pour effectuer le lien des objets
$(PGM): linkerldarm.ld $(OBJECTS)
	$(ARMGNU)ld  -o $(BUILD)/$(PGM) $(OBJECTS) -e main -T linkerldarm.ld -M >$(BUILD)/listing.txt
 
# Régle pour creer les objets 
$(BUILD)/%.o:  $(SOURCE)/%.s $(SOURCE)/constantesARM.inc $(SOURCE)/descStruct.inc
	$(ARMGNU)as   $< -o $@
 

clean:
	$(ARMGNU)rm -rf $(BUILD)/*.o




