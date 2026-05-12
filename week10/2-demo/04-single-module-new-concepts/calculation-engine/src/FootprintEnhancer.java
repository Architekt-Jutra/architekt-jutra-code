package calculationengine;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * New class added in PR — mixes generic concepts with downstream-specific ones.
 * Some new terms are fine (CalculationCache, ComponentBreakdown).
 * Others break the generalization (FrozenFoodSurcharge, GhgScopeClassifier).
 */
public class FootprintEnhancer {

    private final CalculatorRepository repository;

    public FootprintEnhancer(CalculatorRepository repository) {
        this.repository = repository;
    }

    // ✅ Generic concept — fits Calculation Engine language
    public ComponentBreakdown breakdownComponents(ComponentTree tree, CalculationRequest request) {
        List<Component> resolved = tree.resolveApplicability(request);
        return new ComponentBreakdown(resolved, request.getEffectiveDate());
    }

    // ✅ Generic concept — fits Calculation Engine language
    public HistoricalSnapshot snapshotAt(ComponentTree tree, LocalDate historicalDate) {
        return new HistoricalSnapshot(tree, historicalDate,
            repository.resolveValidityAt(tree, historicalDate));
    }

    // ✅ Generic concept — ApplicabilityRule fits existing vocabulary
    public void addApplicabilityRule(Component component, Applicability rule) {
        component.addApplicability(rule);
    }

    // ❌ Breaks generalization — "FrozenFood" is Product Catalog language
    public FootprintResult calculateWithFrozenFoodSurcharge(CalculationRequest request) {
        FootprintResult base = repository.calculate(request);
        FrozenFoodSurcharge surcharge = new FrozenFoodSurcharge();
        return surcharge.apply(base);
    }

    // ❌ Breaks generalization — "GHG Scope" is Emission Factor language
    public String classifyGhgScope(CalculationRequest request) {
        GhgScopeClassifier classifier = new GhgScopeClassifier();
        return classifier.classify(request.getContextParameters());
    }

    // ❌ Breaks generalization — "Auditor" is Compliance & Audit language
    public boolean checkAuditorApproval(ComponentTree tree) {
        AuditorApprovalCheck check = new AuditorApprovalCheck();
        return check.isApproved(tree);
    }

    // ❌ Breaks generalization — "cold chain" is product-specific knowledge
    public boolean checkColdChainCompliance(CalculationRequest request) {
        Map<String, Object> params = request.getContextParameters();
        double temperature = (double) params.getOrDefault("storageTemperature", 0.0);
        return temperature <= -18.0; // Product Catalog knows cold chain rules, not the engine
    }

    // ❌ DOUBLE VIOLATION — "Scope 3" is Emission Factor language in name
    //    AND string leakage inside the method body
    public double getScope3TransportFactor(CalculationRequest request) {
        Map<String, Object> params = request.getContextParameters();
        String category = (String) params.getOrDefault("emissionCategory", "");
        if (category.equals("SCOPE_3_TRANSPORT")) {  // ❌ String leakage! Not in engine's vocabulary
            return 2.5;
        }
        return 1.0;
    }

    // ✅ Generic — retryCount is infrastructure, not domain
    private int retryCount = 3;

    // ✅ Generic — lastCalculated is infrastructure
    private java.time.Instant lastCalculated;
}
