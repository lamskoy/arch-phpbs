.PHONY: help
.PHONY: php80 php81 php74 php73 php72 php71 php70 php56 php55 php54 php53
.PHONY: php8 php7 php5 php5 modern clean all
.DEFAULT_GOAL := help
SHELL=/bin/bash
ifneq ($(SUFFIX),)
_SUFFIX = "@$(SUFFIX)"
else
_SUFFIX = ""
endif
help:
	@echo -e "\e[31mNo target specified\e[0m"
	@echo "Specify valid one to build php"
	@echo
	@echo "To build specific version: make php81"
	@echo "Available targets: php81 php80 php74 php73 php72 php71 php70 php56 php55 php54 php53"
	@echo
	@echo "To build all 8.x: make php8"
	@echo "To build all 7.x: make php7"
	@echo "To build all 5.x: make php5"
	@echo "To build only 7.4, 8.0, 8.1: make modern"
	@echo
	@echo "To clean: make clean"
	@echo
	@echo "To build all stuff: make all"
	@echo
	@echo -n "To append suffix to package names: "
	@echo "make SUFFIX=\"-your-suffix\" <target> "
php80 php81 php74 php73 php72 php71 php70 php56 php55 php54 php53:
	@$(SHELL) builder.sh -p $@$(_SUFFIX)
php8:
	@$(SHELL) builder.sh -p 81$(_SUFFIX),80$(_SUFFIX)
php7:
	@$(SHELL) builder.sh -p 74$(_SUFFIX),73$(_SUFFIX),72$(_SUFFIX),71$(_SUFFIX),70$(_SUFFIX)
php5:
	@$(SHELL) builder.sh -p 56$(_SUFFIX),55$(_SUFFIX),54$(_SUFFIX),53$(_SUFFIX)
modern:
	@$(SHELL) builder.sh -p 81$(_SUFFIX),80$(_SUFFIX),74$(_SUFFIX)
clean:
	@rm -rf packages/ packages-src/ logs/ phpbuilder.*
all: clean php8 php7 php5
