package sales;

import budgetledger.BudgetService;

/**
 * Sales Module calls Budget Ledger — correct direction (specific -> generic).
 * BUT uses Sales-specific language instead of Ledger's generic API.
 *
 * "debituBudzet", "zamowienieId", "produkty" — all Sales language
 * leaking into the call to a generic Ledger.
 * Should call ledgerService.createEntry(accountId, DebitEntry) instead.
 *
 * ANTI-PATTERN (see comment at bottom):
 * "Sales publishes SprzedazZrealizowana, Budget Ledger subscribes"
 * — wrong because Ledger is MORE generic. Generic should not adapt to specific.
 */
public class SalesService {

    private final BudgetService budgetService;  // uses Sales-specific language for Ledger

    public SalesService(BudgetService budgetService) {
        this.budgetService = budgetService;
    }

    public void zlozZamowienie(Zamowienie zamowienie) {
        // ... sales logic ...

        // Uses Ledger with Sales-specific language (wrong vocabulary)
        budgetService.debituBudzet(
            zamowienie.getId(),
            zamowienie.getProdukty()
        );

        // Should be:
        // ledgerService.createEntry(
        //     AccountId.from(zamowienie.getEmissionAccountId()),
        //     DebitEntry.builder()
        //         .transactionId(TransactionId.generate())
        //         .amount(calculateEmissionCost(zamowienie.getProdukty()))
        //         .description("emission debit")
        //         .build()
        // );
    }

    // ANTI-PATTERN: "Just publish an event and let Ledger subscribe"
    //
    // Budget Ledger is MORE generic than Sales.
    // Ledger's language.md says it ledgers anything: sales, returns,
    // corrections, manual adjustments.
    //
    // If Ledger subscribes to SprzedazZrealizowana:
    //   1. Ledger now knows about SprzedazZrealizowana — a Sales concept
    //   2. Tomorrow, Returns also need ledger entries -> Ledger subscribes to ZwrotZrealizowany
    //   3. Next week, Manual Adjustments -> Ledger subscribes to KorekataReczna
    //   4. Ledger becomes a patchwork of foreign event handlers
    //
    // The generic module is no longer generic.
    //
    // Correct: Sales (specific) calls Ledger's generic createEntry() API,
    // translating Sales concepts into Ledger's language.
}
