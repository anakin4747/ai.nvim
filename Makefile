
.PHONY: cqfd
cqfd:
	cqfd init
	cqfd

.PHONY: test tests
test tests:
	-./scripts/run_tests
	./scripts/print_cloc
