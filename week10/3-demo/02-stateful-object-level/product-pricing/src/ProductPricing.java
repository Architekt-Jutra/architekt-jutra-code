package productpricing;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * - Price cannot be negative
 * - Only one active price per validity period (no overlaps)
 * - Price changes emit domain events for downstream consumption
 */
public class ProductPricing {

    private final UUID productId;
    private final List<PriceEntry> priceHistory = new ArrayList<>();
    private PriceEntry currentPrice;
    private final List<DomainEvent> domainEvents = new ArrayList<>();

    public ProductPricing(UUID productId, BigDecimal initialPrice) {
        if (initialPrice.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Price cannot be negative");
        }
        this.productId = productId;
        this.currentPrice = new PriceEntry(initialPrice, Instant.now(), null);
        this.priceHistory.add(currentPrice);
    }

    public Result changePrice(BigDecimal newPrice, Instant effectiveFrom) {
        if (newPrice.compareTo(BigDecimal.ZERO) < 0) {
            return Result.REJECTED_NEGATIVE_PRICE;
        }

        if (currentPrice != null && currentPrice.price().equals(newPrice)) {
            return Result.REJECTED_SAME_PRICE;
        }

        // Close current price validity
        if (currentPrice != null) {
            currentPrice = currentPrice.closeAt(effectiveFrom);
            priceHistory.set(priceHistory.size() - 1, currentPrice);
        }

        // Add new price
        var newEntry = new PriceEntry(newPrice, effectiveFrom, null);
        priceHistory.add(newEntry);
        currentPrice = newEntry;

        domainEvents.add(new PriceChanged(productId, newPrice, effectiveFrom));
        return Result.ACCEPTED;
    }

    public BigDecimal currentPrice() {
        return currentPrice != null ? currentPrice.price() : BigDecimal.ZERO;
    }

    public int priceChangeCount() {
        return priceHistory.size() - 1; // exclude initial
    }

    public List<PriceEntry> priceHistory() {
        return List.copyOf(priceHistory);
    }

    public List<DomainEvent> domainEvents() {
        return List.copyOf(domainEvents);
    }

    public UUID productId() {
        return productId;
    }

    public enum Result {
        ACCEPTED,
        REJECTED_NEGATIVE_PRICE,
        REJECTED_SAME_PRICE
    }

    public record PriceEntry(BigDecimal price, Instant validFrom, Instant validTo) {
        PriceEntry closeAt(Instant closeTime) {
            return new PriceEntry(price, validFrom, closeTime);
        }
    }

    public record PriceChanged(UUID productId, BigDecimal newPrice, Instant effectiveFrom)
        implements DomainEvent {}

    public interface DomainEvent {}
}
