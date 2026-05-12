# Emission Budget Ledger - Ubiquitous Language

## Module Description
**Generalization** (Accounting Archetype) — generic ledger for tracking emission budgets. Manages accounts, entries (debit/credit), balances. Does not know about specific business contexts (sales, returns, corrections, manual adjustments).

## Core Domain Terms
### Account, AccountId, Entry, DebitEntry, CreditEntry, Balance, TransactionId

## Operations
### createEntry(accountId, entry)
Generic entry creation. Any context can post debit or credit entries.
### getBalance(accountId)
Check current balance for an account.

## Integration Points
### Consumers (OHS)
- Sales, Returns, Manual Adjustments — all use generic createEntry() API
