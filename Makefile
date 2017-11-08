#!/usr/bin/make -f
#
#

# Detect OS
OS = $(shell uname -s)

# Defaults
ECHO = echo

# Make adjustments based on OS
# http://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux/27776822#27776822
ifneq (, $(findstring CYGWIN, $(OS)))
	ECHO = /bin/echo -e
endif

# Colors and helptext
NO_COLOR	= \033[0m
ACTION		= \033[32;01m
OK_COLOR	= \033[32;01m
ERROR_COLOR	= \033[31;01m
WARN_COLOR	= \033[33;01m

# Which makefile am I in?
WHERE-AM-I = $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
THIS_MAKEFILE := $(call WHERE-AM-I)

# Echo some nice helptext based on the target comment
HELPTEXT = $(ECHO) "$(ACTION)--->" `egrep "^\# target: $(1) " "$(THIS_MAKEFILE)" | sed "s/\# target: $(1)[ ]*-[ ]* / /g"` "$(NO_COLOR)"

# Check version  and path to command and display on one line
CHECK_VERSION = printf "%-15s %-10s %s\n" "`basename $(1)`" "`$(1) --version $(2)`" "`which $(1)`"



# Add local bin path for test tools
BIN 		= bin
VENDORBIN 	= vendor/bin
NPMBIN		= node_modules/.bin

# LESS and CSS
LESS 		 	= style.less #style1.less #style2.less
LESS_MODULES	= modules/
LESS_OPTIONS 	= --strict-imports --include-path=$(LESS_MODULES)
CSSLINT_OPTIONS = --quiet
FONT_AWESOME 	= modules/font-awesome/fonts/

CSSLINT   := $(NPMBIN)/csslint
STYLELINT := $(NPMBIN)/stylelint
LESSC     := $(NPMBIN)/lessc



# target: help               - Displays help.
.PHONY:  help
help:
	@$(call HELPTEXT,$@)
	@$(ECHO) "Usage:"
	@$(ECHO) " make [target] ..."
	@$(ECHO) "target:"
	@egrep "^# target:" Makefile | sed 's/# target: / /g'



# target: prepare-build      - Clear and recreate the build directory.
.PHONY: prepare-build
prepare-build:
	@$(call HELPTEXT,$@)
	install -d build/css build/lint



# target: clean              - Remove all generated files.
.PHONY:  clean
clean:
	@$(call HELPTEXT,$@)
	rm -rf build
	rm -f npm-debug.log



# target: clean-all          - Remove all installed files.
.PHONY:  clean-all
clean-all: clean
	@$(call HELPTEXT,$@)
	rm -rf node_modules



# target: check              - Check installed tools.
.PHONY:  check
check: npm-version
	@$(call HELPTEXT,$@)



# target: less               - Compile and minify the stylesheet(s).
.PHONY: less
less: prepare-build
	@$(call HELPTEXT,$@)

	$(foreach file, $(LESS), $(LESSC) $(LESS_OPTIONS) $(file) build/css/$(basename $(file)).css; )
	$(foreach file, $(LESS), $(LESSC) --clean-css $(LESS_OPTIONS) $(file) build/css/$(basename $(file)).min.css; )

	cp build/css/*.min.css htdocs/css/



# target: less-install       - Installing the stylesheet(s).
.PHONY: less-install
less-install: less
	@$(call HELPTEXT,$@)
	if [ -d ../htdocs/css/ ]; then cp build/css/*.min.css ../htdocs/css/; fi
	if [ -d ../htdocs/js/ ]; then rsync -a js/ ../htdocs/js/; fi



# target: less-lint          - Lint the less stylesheet(s).
.PHONY: less-lint
less-lint: less
	@$(call HELPTEXT,$@)

	$(foreach file, $(LESS), $(LESSC) --lint $(LESS_OPTIONS) $(file) > build/lint/$(file); )
	- $(foreach file, $(LESS), $(CSSLINT) $(CSSLINT_OPTIONS) build/css/$(basename $(file)).css > build/lint/$(basename $(file)).csslint.css; )
	- $(foreach file, $(LESS), $(STYLELINT) build/css/$(basename $(file)).css > build/lint/$(basename $(file)).stylelint.css; )

	ls -l build/lint/



# target: test               - Execute all tests.
.PHONY: test
test: less-lint
	@$(call HELPTEXT,$@)



# target: update             - Update codebase including submodules.
.PHONY: update
update:
	@$(call HELPTEXT,$@)
	git pull
	git pull --recurse-submodules && git submodule foreach git pull origin master



# target: npm-install        - Install npm development npm packages.
# target: npm-update         - Update npm development npm packages.
# target: npm-version        - Display version for each npm package.
.PHONY: npm-installl npm-update npm-version
npm-install:
	@$(call HELPTEXT,$@)
	npm install

npm-update:
	@$(call HELPTEXT,$@)
	npm update

npm-version:
	@$(call HELPTEXT,$@)
	@$(call CHECK_VERSION, node)
	@$(call CHECK_VERSION, npm)
	@$(call CHECK_VERSION, $(CSSLINT))
	@$(call CHECK_VERSION, $(STYLELINT))
	@$(call CHECK_VERSION, $(LESSC), | cut -d ' ' -f 2)







# target: upgrade-normalize  - Upgrade LESS module - Normalize.
.PHONY: upgrade-normalize
upgrade-normalize:
	@$(call HELPTEXT,$@)
	npm update normalize.css
	cp node_modules/normalize.css/normalize.css modules/normalize.less


# target: upgrade-responsive-menu - Upgrade LESS module - Responsive menu
.PHONY: upgrade-responsive-menu
upgrade-responsive-menu:
	@$(call HELPTEXT,$@)
	npm update desinax-responsive-menu
	cp node_modules/desinax-responsive-menu/src/less/responsive-menu.less modules/
	cp node_modules/desinax-responsive-menu/src/js/responsive-menu.js js/


# target: upgrade                 - Upgrade external LESS modules.
.PHONY: upgrade
upgrade: upgrade-normalize upgrade-responsive-menu
	@$(call HELPTEXT,$@)
