package calculationengine;

public class FootprintCalculator {

    private final ComponentRepository componentRepository;
    private final AuditLogger auditLogger;

    public FootprintCalculator(ComponentRepository componentRepository, AuditLogger auditLogger) {
        this.componentRepository = componentRepository;
        this.auditLogger = auditLogger;
    }

    public FootprintResult calculate(List<Component> components, Map<String, String> contextParameters) {
        FootprintResult result = new FootprintResult();

        for (Component component : components) {
            BigDecimal contribution = component.value().multiply(component.factor());

            // ❌ String leakage: "MROZONKI" is Product Catalog language
            if (contextParameters.getOrDefault("productCategory", "").equals("MROZONKI")) {
                contribution = contribution.multiply(new BigDecimal("1.35")); // refrigeration surcharge
            }

            // ❌ String leakage: "SCOPE_3_TRANSPORT" is Emission Factor Mgmt language
            if (contextParameters.getOrDefault("scope", "").equals("SCOPE_3_TRANSPORT")) {
                contribution = contribution.multiply(ghgProtocolTransportAdjustment());
            }

            // ❌ String leakage: "GHG_PROTOCOL_V2" is Emission Factor Mgmt language
            if (contextParameters.getOrDefault("factorSource", "").equals("GHG_PROTOCOL_V2")) {
                contribution = contribution.setScale(6, RoundingMode.HALF_UP); // protocol-specific rounding
            }

            // ❌ String leakage: "NABIAJ" is Product Catalog language
            if (contextParameters.getOrDefault("productCategory", "").equals("NABIAJ")) {
                contribution = contribution.multiply(new BigDecimal("1.12")); // dairy cold chain factor
            }

            // ❌ String leakage: "CHEMIA" is Product Catalog language
            if (contextParameters.getOrDefault("productCategory", "").equals("CHEMIA")) {
                auditLogger.logHazardousCalculation(component);
            }

            result.addContribution(component.id(), contribution);
        }

        return result;
    }

    private BigDecimal ghgProtocolTransportAdjustment() {
        return new BigDecimal("1.08");
    }
}
