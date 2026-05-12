package productpricing;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Tests at object level — directly on ProductPricing.
 * Strategy: output-based + indirect state-based.
 *
 * Question: ProductPricingFacade is simple and stable (3 lines, no branching).
 * Question: Could these tests live at facade level instead — verifying the effect
 * through getCurrentPrice() after going through DB save/load?
 */
class ProductPricingTest {

    UUID productId = UUID.randomUUID();
    Instant now = Instant.now();

    @Test
    void should_accept_valid_price_change() {
        var pricing = new ProductPricing(productId, new BigDecimal("100.00"));

        var result = pricing.changePrice(new BigDecimal("120.00"), now);

        assertThat(result).isEqualTo(ProductPricing.Result.ACCEPTED);
        assertThat(pricing.currentPrice()).isEqualByComparingTo("120.00");
        assertThat(pricing.priceChangeCount()).isEqualTo(1);
    }

    @Test
    void should_reject_negative_price() {
        var pricing = new ProductPricing(productId, new BigDecimal("100.00"));

        var result = pricing.changePrice(new BigDecimal("-10.00"), now);

        assertThat(result).isEqualTo(ProductPricing.Result.REJECTED_NEGATIVE_PRICE);
        assertThat(pricing.currentPrice()).isEqualByComparingTo("100.00");
    }

    @Test
    void should_reject_same_price() {
        var pricing = new ProductPricing(productId, new BigDecimal("100.00"));

        var result = pricing.changePrice(new BigDecimal("100.00"), now);

        assertThat(result).isEqualTo(ProductPricing.Result.REJECTED_SAME_PRICE);
        assertThat(pricing.priceChangeCount()).isEqualTo(0);
    }

    @Test
    void should_emit_price_changed_event() {
        var pricing = new ProductPricing(productId, new BigDecimal("100.00"));

        pricing.changePrice(new BigDecimal("150.00"), now);

        assertThat(pricing.domainEvents()).hasSize(1);
        assertThat(pricing.domainEvents().get(0))
            .isInstanceOf(ProductPricing.PriceChanged.class);
    }

    @Test
    void should_track_price_history() {
        var pricing = new ProductPricing(productId, new BigDecimal("100.00"));

        pricing.changePrice(new BigDecimal("120.00"), now);
        pricing.changePrice(new BigDecimal("90.00"), now.plusSeconds(3600));

        assertThat(pricing.priceHistory()).hasSize(3); // initial + 2 changes
        assertThat(pricing.currentPrice()).isEqualByComparingTo("90.00");
        assertThat(pricing.priceChangeCount()).isEqualTo(2);
    }
}
