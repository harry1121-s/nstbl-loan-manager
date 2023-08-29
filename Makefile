# Build and test

profile ?=default

build:
	@FOUNDRY_PROFILE=production forge build

test:
	forge test

testToken:
	forge test --match-path ./tests/unit/Token.t.sol

testLoanManager:
	forge test --match-path ./tests/unit/LoanManager.t.sol --fork-url https://eth-mainnet.g.alchemy.com/v2/CFhLkcCEs1dFGgg0n7wu3idxcdcJEgbW -vvvvv

debug: 
	forge test -vvvvv

clean:
	@forge clean