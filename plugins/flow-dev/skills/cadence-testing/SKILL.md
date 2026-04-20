---
name: cadence-testing
description: |
  Guide for writing, running, and debugging unit tests for Cadence smart contracts using the built-in Cadence Testing Framework and `flow test`. Covers test file structure (_test.cdc, setup/beforeEach/tearDown), assertions and matchers, blockchain emulation (accounts, deployments, events, time manipulation), coverage reports, CI integration, and testing patterns.
  TRIGGER when: writing Cadence unit tests, debugging failing tests, using Test.assert / Test.expect / Test.assertEqual / Test.expectFailure, matchers (Test.equal, Test.beGreaterThan, etc.), Test.newEmulatorBlockchain, executeTransaction / executeScript in tests, moveTime, eventsOfType in tests, `flow test`, `flow test --cover`, coverage reports, `_test.cdc`, "how do I test this contract", "test is flaky", "mock a capability in a test".
  DO NOT TRIGGER when: writing contract or transaction code itself (use cadence-lang), generating new contracts/transactions from scratch (use cadence-scaffold), auditing non-test code for security (use cadence-audit), running flow CLI commands other than `flow test` (use flow-cli), setting up flow.json contract aliases outside a testing context (use flow-project-setup).
---

# Cadence Testing Guide

Write and run unit tests for Cadence smart contracts using the built-in `Test` contract and the Flow CLI's `flow test` command. Tests are Cadence files named `*_test.cdc` that get an emulator blockchain, deploy contracts, execute scripts and transactions, and assert expected behavior.

## Key Principles

1. **Lifecycle is fixed** — `setup()` runs once, `beforeEach()` / `afterEach()` wrap every test, `testXxx()` functions are the test cases, and `tearDown()` runs once at the end. All are optional except the test functions.
2. **Start each test from a clean state** — create the blockchain in `setup()` and either reset snapshots per test or create fresh resources in `beforeEach()`.
3. **Use the right assertion** — `Test.assert(cond, msg?)` for boolean checks, `Test.assertEqual(expected, actual)` for equality, `Test.expect(value, matcher)` for matcher-based checks, and `Test.expectFailure(closure, errorSubstring)` for expected failures.
4. **Cover failure paths** — access-control denials, pre/post-condition violations, and resource-ownership errors are the parts of the contract that bugs hide in. Every test file should include at least one `expectFailure` case.

## Navigation

| Task | Reference |
|------|-----------|
| Project layout, `flow.json` test aliases, lifecycle, first test | [setup-and-basics.md](references/setup-and-basics.md) |
| Assertions, matchers, combinators, custom matchers, `expectFailure` | [assertions-and-matchers.md](references/assertions-and-matchers.md) |
| Accounts, deployments, scripts, transactions, `reset`, `moveTime`, mocking | [blockchain-emulation.md](references/blockchain-emulation.md) |
| Events and logs — reading, filtering, asserting | [events-and-logs.md](references/events-and-logs.md) |
| Running tests, coverage, determinism, fork mode, CI | [coverage-and-ci.md](references/coverage-and-ci.md) |
| Testing patterns, isolation, flakiness prevention, anti-patterns | [patterns.md](references/patterns.md) |

## Running Tests — Quick Reference

```bash
flow test                                 # run every *_test.cdc it can find
flow test cadence/tests/Counter_test.cdc  # run a specific file
flow test --cover                         # with coverage report
flow test --name testMintWorks            # only tests whose name matches
flow test --seed 42                       # deterministic random order
```

Full flag reference and CI integration live in [coverage-and-ci.md](references/coverage-and-ci.md).

## Companion Skills

- **`cadence-lang`** — Essential. Tests are Cadence too; all access control, resource, and capability rules apply.
- **`cadence-scaffold`** — Generate the contracts and transactions you're about to test.
- **`cadence-audit`** — After writing tests, audit the contracts they cover. Audit findings often point back at missing tests.
- **`flow-cli`** — Background on non-test CLI commands. This skill covers `flow test` in depth.
- **`flow-project-setup`** — Configuring `flow.json` outside a testing context.
