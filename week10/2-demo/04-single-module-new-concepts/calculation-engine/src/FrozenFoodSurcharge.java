package calculationengine;

/**
 * ❌ This entire class is a violation.
 * "FrozenFood" and "Surcharge" in a product-specific sense don't belong in the Calculation Engine.
 * The engine is generic — it calculates footprints via components, not product-category surcharges.
 */
public class FrozenFoodSurcharge {
    private static final double COLD_CHAIN_MULTIPLIER = 1.35;  // ❌ "cold chain" is Product Catalog language
    private static final double REFRIGERATION_FACTOR = 0.8;     // ❌ "refrigeration" is product-specific

    // ❌ Product Catalog-specific fields in Calculation Engine module
    private String productCategory;  // ❌ "productCategory" is Product Catalog language
    private double freezerEnergyKwh; // ❌ "freezerEnergy" is product-specific knowledge

    public FrozenFoodSurcharge() {
        this.productCategory = "FROZEN";  // ❌ String leakage — product category literal
    }

    // ❌ Product-specific calculation in generic engine
    public FootprintResult apply(FootprintResult baseResult) {
        double surcharge = baseResult.getValue() * COLD_CHAIN_MULTIPLIER + freezerEnergyKwh * REFRIGERATION_FACTOR;
        return new FootprintResult(baseResult.getValue() + surcharge, baseResult.getUnit());
    }

    // ❌ Product-specific check — "perishable" is Product Catalog concept
    public boolean isPerishable() {
        return productCategory.equals("FROZEN") || productCategory.equals("CHILLED");
    }
}
