TESTS_INIT = tests/minimal_init.vim
TESTS_DIR = tests/

.PHONY: test tests
test tests:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"
