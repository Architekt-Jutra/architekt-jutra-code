package calculationengine;

import java.time.LocalDate;
import java.util.List;

/**
 * ✅ This class is fine — ComponentBreakdown is a generic Calculation Engine concept.
 * Makes sense without knowing about any specific downstream.
 */
public class ComponentBreakdown {
    private final List<Component> resolvedComponents;
    private final LocalDate effectiveDate;

    public ComponentBreakdown(List<Component> resolvedComponents, LocalDate effectiveDate) {
        this.resolvedComponents = resolvedComponents;
        this.effectiveDate = effectiveDate;
    }

    public double getTotalFootprint() {
        return resolvedComponents.stream()
            .mapToDouble(Component::getCalculatedValue)
            .sum();
    }

    public List<Component> getResolvedComponents() {
        return resolvedComponents;
    }

    public int getComponentCount() {
        return resolvedComponents.size();
    }
}
