package calculator;

import java.math.BigDecimal;
import java.util.List;

/**
 * Pure function: products + context → discount amount.
 * No state. No side effects.
 */
public class DiscountPolicy {

    public BigDecimal calculateDiscount(List<Product> products, PricingContext context) {
        BigDecimal total = products.stream()
            .map(p -> p.price().multiply(BigDecimal.valueOf(p.quantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        if (products.size() >= 5) {
            return total.multiply(new BigDecimal("0.10")); // 10% bulk discount
        }
        if (context.isLoyalCustomer()) {
            return total.multiply(new BigDecimal("0.05")); // 5% loyalty
        }
        return BigDecimal.ZERO;
    }
}
