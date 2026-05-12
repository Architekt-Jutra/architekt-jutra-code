# Product Catalog - Ubiquitous Language

## Module Description
Manages products, categories, SKUs. Owns product classification and category hierarchy.

## Core Domain Terms
### Product, KategoriaProdukt, SKU, Mrozonka, CategoryHierarchy

## Domain Events
### ProductCategoryChanged
Product moved to different category. Contains: productId, kategoriaProdukt, isMrozonka, previousCategory.
### ProductCreated
New product added. Contains: productId, sku, kategoriaProdukt.

## Integration Points
### Footprint Calculation Engine (publishes events — engine may react)
- Publishes ProductCategoryChanged when product classification changes
- Publishes ProductCreated when new products are added
