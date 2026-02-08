
.PHONY: cqfd
cqfd:
	git submodule update --init
	./scripts/cqfd/cqfd init
	./scripts/cqfd/cqfd

.PHONY: test tests
test tests:
	-./scripts/run_tests
	./scripts/print_cloc
