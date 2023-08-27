# Nealthy Loan manager V1

## Overview

This repository contains the core contracts of the nSTBL V1 protocol that are responsible for the deployment and management of Nealthy Loan Manager


| Contract | Description |
| -------- | ------- |
| [`LoanManager`](https://github.com/) | LoanManager contains the logic for borrowing assets from NSTBL vault to generate yield from maple cash pools |
| [`LoanManagerStorage`](https://github.com/) | Contains all the storage variables for LoanManager contracts, upon upgrade new storage variables should be added to the bottom of this file |
| [`LMTokenLP`](https://github.com/) | ERC20 token that is an LP token issued to nSTBL vault when LoanManager borrows assets from NSTBL vault. |

## Dependencies/Inheritance

## Setup


## Commands
To make it easier to perform some tasks within the repo, a few commands are available through a makefile:

### Build Commands

| Command | Action |
|---|---|
| `make build` | Compile all contracts in the repo, including submodules. |
| `make clean` | Delete cached files. |


## About Nealthy

[Nealthy](https://www.nealthy.com) is a VARA regulated crypto asset management company. Nealthy provides on-chain index products for KYC/KYB individuals and institutions to invest in. 