package productpricing;

import java.util.UUID;

public interface ProductPricingRepository {
    ProductPricing findById(UUID productId);
    void save(ProductPricing pricing);
}
