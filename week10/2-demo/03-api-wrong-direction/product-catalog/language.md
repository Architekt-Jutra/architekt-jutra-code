# Product Catalog - Ubiquitous Language

## Module Description
Manages products, categories, SKUs. Knows about product hierarchies, attributes, and classification.

## Core Domain Terms
### Produkt (Product), ProduktId, Kategoria (Category), SKU, AtrybutProduktu (ProductAttribute)

## Operations
### dodajProdukt(product)
Add a new product to the catalog.
### przypiszKategorie(productId, categoryId)
Assign product to a category.

## Integration Points
### Footprint Calculation Engine (OHS — Product Catalog consumes Calculation Engine's generic API)
- Calls calculateFootprint() to get product footprint
- Imports: ProductId, CalculationContext, AsOfDate
### Emission Factor Management (should NOT call directly — should go through Calculation Engine)
- Currently calls emissionFactorService.getFactorForCategory() — VIOLATION
