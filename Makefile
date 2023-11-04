# Build and test

profile ?=default

build:
	@FOUNDRY_PROFILE=production forge build

test:
	@forge test

testToken:
	@forge test --match-path ./tests/unit/Token.t.sol

testLoanManager:
	@forge test --match-path ./tests/unit/LoanManager.t.sol -vvv --gas-report

debug: 
	@forge test -vvvvv

clean:
	@forge clean

git:
	@git add .
	git commit -m "$m"
	git push

coverage:
	@forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

slither:
	@solc-select use 0.8.21 && \
	slither . 

.PHONY: install build test debug clean git coverage slither