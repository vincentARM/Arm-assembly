# Makefile  Lancer par make PGM=nomexecutable
# r�pertoire des utilitaires
ARMGNU ?= /usr/bin/

# r�pertoire des sources
SOURCE = src


# r�pertoire des objets et de l'executable final
BUILD = build

# nom des objets d�duits des noms des sources du r�pertoire SOURCE
OBJECTS = $(patsubst $(SOURCE)/%.s,$(BUILD)/%.o,$(wildcard $(SOURCE)/*.s))

# R�gle pour g�n�rer l'executable
all: $(PGM)

 
# R�gle pour effectuer le lien des objets
$(PGM): linkerldarm.ld $(OBJECTS)
	$(ARMGNU)ld  -o $(BUILD)/$(PGM) $(OBJECTS) -e main -T linkerldarm.ld -M >$(BUILD)/listing.txt
 
# R�gle pour creer les objets 
$(BUILD)/%.o:  $(SOURCE)/%.s $(SOURCE)/constantesARM.inc $(SOURCE)/descStruct.inc
	$(ARMGNU)as   $< -o $@
 

clean:
	$(ARMGNU)rm -rf $(BUILD)/*.o




