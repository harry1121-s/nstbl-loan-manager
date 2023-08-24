# Submodule management

install:
	@git submodule update --init --recursive

# Build and test

profile ?=default

build:
	@FOUNDRY_PROFILE=production forge build

test:
	forge test

testToken:
	forge test --match-path ./tests/Token.t.sol

debug: 
	forge test -vvvvv

clean:
	@forge clean