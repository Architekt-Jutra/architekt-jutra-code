package calculationengine;

import productcatalog.events.ProductCategoryChanged;
import productcatalog.events.ProductCreated;

/**
 * Same pattern -- Engine subscribes to Product Catalog events directly.
 * Catalog language in Engine: ProductCategoryChanged, getKategoriaProdukt,
 * isMrozonka, ProductCreated, getSku.
 */
public class ProductCatalogEventHandler {

    private final CalculationService calculationService;

    public ProductCatalogEventHandler(CalculationService calculationService) {
        this.calculationService = calculationService;
    }

    @EventListener
    public void handle(ProductCategoryChanged event) {
        ComponentId componentId = ComponentId.from(event.getProductId());

        // downstream language: "kategoriaProdukt", "isMrozonka"
        String category = event.getKategoriaProdukt();
        if (event.isMrozonka()) {
            calculationService.applyFrozenProductMultiplier(componentId, category);
        } else {
            calculationService.reassignComponentTree(componentId, category);
        }
    }

    @EventListener
    public void handle(ProductCreated event) {
        // downstream language: "sku", "kategoriaProdukt"
        calculationService.initializeComponent(
            ComponentId.from(event.getProductId()),
            event.getSku(),
            event.getKategoriaProdukt()
        );
    }
}
