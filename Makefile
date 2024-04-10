SCRIPTS := $(wildcard *.sh)
PREFIX  ?= /opt/sysadmin-scripts

.PHONY: lint install

lint:
	shellcheck $(SCRIPTS)

install:
	install -d $(PREFIX)
	install -m 0755 $(SCRIPTS) $(PREFIX)/
