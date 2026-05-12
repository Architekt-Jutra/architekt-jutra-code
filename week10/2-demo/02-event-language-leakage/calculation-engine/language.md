# Footprint Calculation Engine - Ubiquitous Language

## Module Description
**Generalization** — calculates kg CO2 footprint for any input using the pricing archetype (pure functions). Generic — does not know what products it prices or where emission factors come from.

## Core Domain Terms
### Component, Calculator, Validity, FootprintResult, CalculationContext, ComponentTree, ApplicabilityCondition

## Operations
### calculateFootprint, refreshComponent, invalidateCalculation

## Domain Events
### FootprintCalculated, ComponentInvalidated

## Integration Points
### Consumers (OHS)
- Emission Factor Management context, Product Catalog context — provide data that feeds calculations
