package calculator;

import java.math.BigDecimal;

public record Product(
    String id,
    BigDecimal price,
    int quantity,
    boolean requiresColdChain,
    boolean isHazardous
) {}
