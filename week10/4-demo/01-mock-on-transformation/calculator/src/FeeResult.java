package calculator;

import java.math.BigDecimal;

public record FeeResult(
    BigDecimal baseAmount,
    BigDecimal discount,
    BigDecimal surcharge,
    BigDecimal total
) {}
