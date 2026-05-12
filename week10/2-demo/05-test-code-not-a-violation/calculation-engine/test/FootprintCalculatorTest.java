package calculationengine;

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

class FootprintCalculatorTest {

    private final FootprintCalculator calculator = new FootprintCalculator(
        new InMemoryComponentRepository(), new NoOpAuditLogger()
    );

    @Test
    void mrozonki_z_cold_chain_dostaja_narzut_chlodzenia() {
        // Arrange — opowiadamy historyjke biznesowa w jezyku Product Catalog
        var mrozonePielmieni = component("pielmieni-500g")
            .withValue(new BigDecimal("2.5"))
            .withFactor(new BigDecimal("1.0"))
            .withColdChainSurcharge(true, new BigDecimal("1.35"))
            .build();

        // Act
        FootprintResult result = calculator.calculate(
            List.of(mrozonePielmieni),
            Map.of("requiredPrecision", 2)
        );

        // Assert
        assertThat(result.totalFootprint()).isEqualByComparingTo("3.375");
    }

    @Test
    void wspolczynnik_ghg_protocol_v2_wymaga_6_miejsc_dziesietnych() {
        // Arrange — uzywamy slownictwa Emission Factor Management
        var wspolczynnikScope1 = component("co2-transport-scope1")
            .withValue(new BigDecimal("1.123456789"))
            .withFactor(new BigDecimal("1.0"))
            .build();

        // Act — precyzja GHG Protocol V2
        FootprintResult result = calculator.calculate(
            List.of(wspolczynnikScope1),
            Map.of("requiredPrecision", 6)
        );

        // Assert
        assertThat(result.totalFootprint()).isEqualByComparingTo("1.123457");
    }

    @Test
    void nabiaj_i_mrozonki_oba_z_narzutem_cold_chain_ale_roznym_wspolczynnikiem() {
        var jogurtGrecki = component("jogurt-grecki-400g")
            .withValue(new BigDecimal("1.8"))
            .withFactor(new BigDecimal("1.0"))
            .withColdChainSurcharge(true, new BigDecimal("1.12"))
            .build();

        var lodyWaniliowe = component("lody-waniliowe-1l")
            .withValue(new BigDecimal("3.2"))
            .withFactor(new BigDecimal("1.0"))
            .withColdChainSurcharge(true, new BigDecimal("1.35"))
            .build();

        FootprintResult result = calculator.calculate(
            List.of(jogurtGrecki, lodyWaniliowe),
            Map.of()
        );

        // jogurt: 1.8 * 1.12 = 2.016, lody: 3.2 * 1.35 = 4.32
        assertThat(result.totalFootprint()).isEqualByComparingTo("6.34");
    }

    @Test
    void chemia_gospodarcza_bez_narzutu_cold_chain() {
        var plynDoNaczyn = component("plyn-fairy-900ml")
            .withValue(new BigDecimal("0.9"))
            .withFactor(new BigDecimal("1.0"))
            .withColdChainSurcharge(false, BigDecimal.ONE)
            .build();

        FootprintResult result = calculator.calculate(
            List.of(plynDoNaczyn), Map.of()
        );

        assertThat(result.totalFootprint()).isEqualByComparingTo("0.90");
    }

    private ComponentBuilder component(String name) {
        return new ComponentBuilder(name);
    }
}
