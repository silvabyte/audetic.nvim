.PHONY: fmt lint check

fmt:
	stylua lua/

lint:
	selene lua/

check: fmt lint
