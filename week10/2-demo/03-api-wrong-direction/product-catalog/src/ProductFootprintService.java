package productcatalog;

import emissionfactors.EmissionFactorService;
import emissionfactors.WskaznikEmisji;
import emissionfactors.Zakres;

/**
 * Product Catalog calls Emission Factor Management directly
 * instead of going through the Footprint Calculation Engine's generic API.
 *
 * "getFactorForCategory", "WskaznikEmisji", "Zakres" — all Emission Factors
 * language leaking into Product Catalog.
 * Should call calculationEngine.calculateFootprint() instead.
 */
public class ProductFootprintService {

    private final EmissionFactorService emissionFactorService;  // should not depend on Emission Factors

    public ProductFootprintService(EmissionFactorService emissionFactorService) {
        this.emissionFactorService = emissionFactorService;
    }

    public double obliczSladWeglowyProduktu(Produkt produkt) {
        // API call to Emission Factors' specific API — uses Emission Factors language
        WskaznikEmisji wskaznik = emissionFactorService.getFactorForCategory(
            produkt.getKategoria()
        );

        // Uses Emission Factors-specific concepts (Zakres, WskaznikEmisji)
        double footprint = produkt.getWaga() * wskaznik.getWartosc(Zakres.SCOPE_1);

        return footprint;

        // Should be:
        // FootprintResult result = calculationEngine.calculateFootprint(
        //     ProductId.from(produkt.getId()),
        //     CalculationContext.forProduct(produkt.getKategoria()),
        //     AsOfDate.now()
        // );
        // return result.getTotalFootprint();
    }
}
