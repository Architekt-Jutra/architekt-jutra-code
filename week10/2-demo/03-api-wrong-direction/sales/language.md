# Sales Module - Ubiquitous Language

## Module Description
Manages orders, sales, customers. Knows about sales processes, pricing, and customer relationships.

## Core Domain Terms
### Zamowienie (Order), ZamowienieId, Klient (Customer), Produkty (Products), StatusZamowienia (OrderStatus)

## Operations
### zlozZamowienie(order)
Place a new sales order.

## Domain Events
### SprzedazZrealizowana (SaleCompleted)
Published when a sale is completed.

## Integration Points
### Emission Budget Ledger (OHS — Sales consumes Ledger's generic API)
- Calls createEntry() to debit emission budget when sale happens
- Imports: AccountId, DebitEntry, TransactionId
