package calculationengine;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;

public class FootprintCalculator {

    private final ComponentRepository componentRepository;
    private final AuditLogger auditLogger;

    public FootprintCalculator(ComponentRepository componentRepository, AuditLogger auditLogger) {
        this.componentRepository = componentRepository;
        this.auditLogger = auditLogger;
    }

    public FootprintResult calculate(List<Component> components, Map<String, Object> contextParameters) {
        FootprintResult result = new FootprintResult();
        for (Component component : components) {
            BigDecimal contribution = component.value().multiply(component.factor());
            if (component.requiresColdChainSurcharge()) {
                contribution = contribution.multiply(component.coldChainSurchargeFactor());
            }
            int precision = (int) contextParameters.getOrDefault("requiredPrecision", 2);
            contribution = contribution.setScale(precision, RoundingMode.HALF_UP);
            result.addContribution(component.id(), contribution);
        }
        auditLogger.log("calculation_completed", result.totalFootprint());
        return result;
    }
}
