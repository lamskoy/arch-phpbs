.PHONY: help
.PHONY: php80 php81 php82 php83 php84 php74 php73 php72 php71 php70 php56
.PHONY: php8 php7 php5 php5 clean all
.DEFAULT_GOAL := help
BUILDER=phpbs
SHELL=/bin/bash
help:
	@$(SHELL) $(BUILDER) $@
php80 php81 php82 php83 php84 php74 php73 php72 php71 php70 php56 php8 php7 php5:
	@$(SHELL) $(BUILDER) $@ --suffix=$(SUFFIX) --sources=$(SOURCES)
clean:
	@rm -rf packages/ packages-src/ logs/ phpbuilder.*
all:
	@$(SHELL) $(BUILDER) all --suffix=$(SUFFIX) --sources=$(SOURCES)
