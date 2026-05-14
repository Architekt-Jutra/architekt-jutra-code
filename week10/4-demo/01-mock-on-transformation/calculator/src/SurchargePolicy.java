package calculator;

import java.math.BigDecimal;
import java.util.List;

/**
 * Pure function: products + context → surcharge amount.
 * No state. No side effects.
 */
public class SurchargePolicy {

    public BigDecimal calculateSurcharge(List<Product> products, PricingContext context) {
        BigDecimal surcharge = BigDecimal.ZERO;

        for (Product product : products) {
            if (product.requiresColdChain()) {
                surcharge = surcharge.add(
                    product.price().multiply(new BigDecimal("0.15"))
                );
            }
            if (product.isHazardous()) {
                surcharge = surcharge.add(new BigDecimal("25.00")); // flat hazmat fee
            }
        }

        if (context.isExpressDelivery()) {
            surcharge = surcharge.add(new BigDecimal("9.99"));
        }

        return surcharge;
    }
}
