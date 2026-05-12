# Footprint Calculation Engine - Ubiquitous Language

## Module Description
**Generalization** — calculates kg CO2 from components using a pure-function pricing archetype. Generic — does NOT know what type of product it calculates for. Knows: Components, Calculators, Validity, Applicability, Context Parameters.

## Core Domain Terms
### Component
A single element contributing to a footprint calculation. Has a value, unit, and optional adjustment properties.
### Calculator
A pure function that takes Components and Context Parameters, produces a footprint result in kg CO2.
### Validity
Time period during which a calculation configuration (components, rates) is effective.
### Applicability
Conditions under which a specific Calculator or Component applies (e.g., region, channel, weight class).
### ContextParameter
A named key-value pair passed into the Calculator to influence calculation behavior. Generic — the engine does not interpret their meaning.
### FootprintResult
Output of a calculation: total kg CO2, breakdown by component, validity period of the result.

## Operations
### calculate(components, contextParameters)
Run calculation. Components carry generic properties (requiresColdChainSurcharge, adjustmentFactor, regulatoryPrecision). Returns FootprintResult.
### validateApplicability(components, contextParameters)
Check whether a Calculator applies to the given context.
### resolveValidity(calculatorId, asOfDate)
Find the valid configuration for a calculator at a given date.

## Integration Points
### Consumers (OHS — this module exposes generic calculation API, consumers adapt)
- Product Catalog context — submits product-related components for footprint calculation
- Emission Factor Management context — provides emission factors as components
- Any future consumer — same generic API
