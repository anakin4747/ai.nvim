
.PHONY: cqfd
cqfd:
	git submodule update --init
	./scripts/cqfd/cqfd init
	./scripts/cqfd/cqfd run make tests

.PHONY: test tests
test tests:
	-./scripts/run_tests | grep -v '^test-message-payload$$'
	@./scripts/print_cloc
