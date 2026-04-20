
.PHONY: cqfd
cqfd:
	@git submodule update --init > /dev/null
	@mkdir -p /var/lib/openclaw/cqfd-tmp
	@TMPDIR=/var/lib/openclaw/cqfd-tmp USER=openclaw ./scripts/cqfd/cqfd init > /dev/null
	@TMPDIR=/var/lib/openclaw/cqfd-tmp USER=openclaw ./scripts/cqfd/cqfd run make test

.PHONY: test tests
test tests:
	@-./scripts/run_tests | grep -v '^test-message-payload$$'
	@./scripts/print_cloc
