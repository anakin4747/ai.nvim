TESTS_INIT = tests/minimal_init.lua
TESTS_DIR = tests/

.PHONY: cqfd
cqfd: cqfd_init
	cqfd

.PHONY: cqfd_init
cqfd_init:
	cqfd init

.PHONY: cloc
cloc: test
	@which cloc &> /dev/null || ( printf "\033[32mYou don't have cloc installed\033[0m\n" && exit 1 )
	@cloc . | \
		awk '/^-+$$/ {p=1} p' | \
		tr 'A-Z' 'a-z' | \
		sed 's/vim script/vimscript /' | \
		sed 's/bourne again shell/bash              /' | \
		sed 's/bourne shell/bash        /' | \
		awk '/json/ {print "\033[32mtest code:\033[0m"; print; next} {print}' | \
		awk '/vimscript/ {print "\033[32mapplication code:\033[0m"; print; print "\033[32mother:\033[0m"; next} {print}' | \
		sed '/^\(test code:\|application code:\|other:\)/!s/^\([a-z][a-z0-9_ :]*\)  \{1,\}/ \1 /' | \
		sed 's/ language/language /'

.PHONY: test tests
test tests:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"
