package calculator;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

public class FeeCalculator {

    private final DiscountPolicy discountPolicy;
    private final SurchargePolicy surchargePolicy;

    public FeeCalculator(DiscountPolicy discountPolicy, SurchargePolicy surchargePolicy) {
        this.discountPolicy = discountPolicy;
        this.surchargePolicy = surchargePolicy;
    }

    /**
     * Pure transformation: takes products + context, returns fee.
     * No state mutation. No side effects. No database.
     * DiscountPolicy and SurchargePolicy are also pure functions.
     */
    public FeeResult calculate(List<Product> products, PricingContext context) {
        BigDecimal baseAmount = products.stream()
            .map(p -> p.price().multiply(BigDecimal.valueOf(p.quantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal discount = discountPolicy.calculateDiscount(products, context);
        BigDecimal surcharge = surchargePolicy.calculateSurcharge(products, context);

        BigDecimal total = baseAmount
            .subtract(discount)
            .add(surcharge)
            .setScale(2, RoundingMode.HALF_UP);

        return new FeeResult(baseAmount, discount, surcharge, total);
    }
}
