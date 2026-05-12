# Footprint Calculation Engine - Ubiquitous Language

## Module Description
**Generalization** (Pricing Archetype) — generic footprint calculation engine. Calculates carbon footprint for any product given context and date. Does not know about specific products, categories, or emission factor sources.

## Core Domain Terms
### FootprintResult, CalculationContext, ProductId, AsOfDate, ComponentTree

## Operations
### calculateFootprint(productId, context, asOfDate)
Generic footprint calculation. Any context can request a calculation.

## Integration Points
### Consumers (OHS)
- Product Catalog, Sales, Reporting — all consume the same generic API
