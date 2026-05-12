# Product Catalog - Ubiquitous Language

## Module Description
Manages products, their categories, SKUs, and pricing. Specific to the retail/manufacturing domain. Knows about product types, storage requirements, and category-specific regulations.

## Core Domain Terms
### Produkt (Product)
A sellable item with a name, SKU, category, and price.
### Kategoria (Category)
Product classification: MROZONKI (frozen food), NABIAJ (dairy), ELEKTRONIKA (electronics), CHEMIA (chemicals), OWOCE (fruits & vegetables).
### SKU
Stock Keeping Unit — unique product identifier.
### Cena (Price)
Product price in PLN.
### WymagaChłodzenia (Requires Refrigeration)
Flag on products that need cold chain logistics (frozen food, dairy).
### WymagaSpecjalnegoOpakowania (Requires Special Packaging)
Flag on products needing protective packaging (electronics, chemicals).

## Operations
### dodajProdukt(nazwa, kategoria, sku, cena)
Add a new product to the catalog.
### zmienKategorie(produktId, nowaKategoria)
Change product category — may affect footprint calculation requirements.

## Domain Events
### ProduktDodany
Published when a new product is created. Contains: produktId, kategoria, sku.
### KategoriZmieniona
Published when product category changes. Contains: produktId, stara, nowa.

## Integration Points
### Footprint Calculation Engine (OHS — Product Catalog consumes Engine's generic API)
- Calls `calculate()` to get footprint for a product
- Maps: kategoria -> Applicability conditions, product properties -> ContextParameters
- Sets: requiresColdChainSurcharge=true for MROZONKI/NABIAJ products
