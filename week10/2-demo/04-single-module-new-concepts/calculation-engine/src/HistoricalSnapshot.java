package calculationengine;

import java.time.LocalDate;
import java.util.Map;

/**
 * ✅ This class is fine — HistoricalSnapshot is a generic Calculation Engine concept.
 * Querying footprint state at a past date makes sense without knowing about any specific downstream.
 */
public class HistoricalSnapshot {
    private final ComponentTree tree;
    private final LocalDate snapshotDate;
    private final Map<Component, Validity> resolvedValidities;

    public HistoricalSnapshot(ComponentTree tree, LocalDate snapshotDate,
                              Map<Component, Validity> resolvedValidities) {
        this.tree = tree;
        this.snapshotDate = snapshotDate;
        this.resolvedValidities = resolvedValidities;
    }

    public FootprintResult recalculate(CalculationRequest request) {
        // Recalculate using component versions valid at snapshotDate
        CalculationRequest historicalRequest = request.withEffectiveDate(snapshotDate);
        return tree.calculate(historicalRequest, resolvedValidities);
    }

    public LocalDate getSnapshotDate() {
        return snapshotDate;
    }

    public boolean hasExpiredComponents() {
        return resolvedValidities.values().stream()
            .anyMatch(v -> v.getEffectiveTo().isBefore(snapshotDate));
    }
}
