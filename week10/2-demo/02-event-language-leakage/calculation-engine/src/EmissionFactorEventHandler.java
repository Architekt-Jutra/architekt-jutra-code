package calculationengine;

import emissionfactors.events.EmissionFactorUpdated;
import emissionfactors.events.AuditorLockedCategory;

/**
 * Calculation Engine directly subscribes to Emission Factor Management events.
 * Engine's code is full of downstream language: EmissionFactorUpdated, getGhgScope,
 * getAuditorId, getProtocolVersion, AuditorLockedCategory.
 *
 * Physical direction: Factor Mgmt publishes -> Engine subscribes (looks OK)
 * Linguistic direction: Factor Mgmt language leaks INTO Engine (violation!)
 */
public class EmissionFactorEventHandler {

    private final CalculationService calculationService;

    public EmissionFactorEventHandler(CalculationService calculationService) {
        this.calculationService = calculationService;
    }

    @EventListener
    public void handle(EmissionFactorUpdated event) {
        ComponentId componentId = ComponentId.from(event.getFactorId());
        BigDecimal newValue = event.getNewValue();

        // downstream language: "ghgScope", "protocolVersion"
        if (event.getGhgScope().equals("SCOPE_1")) {
            calculationService.refreshComponent(componentId, newValue, "DIRECT");
        } else {
            calculationService.refreshComponent(componentId, newValue, "INDIRECT");
        }
    }

    @EventListener
    public void handle(AuditorLockedCategory event) {
        // downstream language: "auditorId", "categoryId", "lockExpiry"
        String categoryId = event.getCategoryId();
        calculationService.invalidateComponentsByCategory(categoryId, event.getLockExpiry());
    }
}
