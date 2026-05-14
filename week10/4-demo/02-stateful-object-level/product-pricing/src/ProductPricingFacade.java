package productpricing;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Application service — simple orchestrator:
 * 1. Load object from DB
 * 2. Call domain method
 * 3. Save
 *
 * Stable — hasn't changed in months.
 * Few steps, no branching, no external calls beyond DB.
 */
public class ProductPricingFacade {

    private final ProductPricingRepository repository;

    public ProductPricingFacade(ProductPricingRepository repository) {
        this.repository = repository;
    }

    public ProductPricing.Result changePrice(UUID productId, BigDecimal newPrice, Instant effectiveFrom) {
        ProductPricing pricing = repository.findById(productId);
        ProductPricing.Result result = pricing.changePrice(newPrice, effectiveFrom);
        repository.save(pricing);
        return result;
    }

    public BigDecimal getCurrentPrice(UUID productId) {
        return repository.findById(productId).currentPrice();
    }

    public int getPriceChangeCount(UUID productId) {
        return repository.findById(productId).priceChangeCount();
    }
}
