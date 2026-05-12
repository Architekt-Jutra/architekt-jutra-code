# Footprint Calculation Engine - Ubiquitous Language

## Module Description
**Generalization** — calculates carbon footprint for any input using composable components, calculators, validity periods, and applicability rules. Generic — does NOT know about specific product types, emission standards, or audit processes.

## Core Domain Terms
### Calculator
Pure function that computes a footprint value from input parameters. Stateless and composable.
### Component
Building block of a calculation. SimpleComponent (leaf) or CompositeComponent (tree).
### Validity
Time-bounded version of a calculator or component configuration. Effective from/to dates.
### Applicability
Condition that determines whether a component or calculator applies to a given input context.
### ContextParameter
A named dimension passed into the calculation (e.g., weight, distance, quantity). The engine is agnostic to what these parameters represent.
### FootprintResult
Output of a calculation — a numeric value with unit (e.g., kgCO2e).
### CalculationRequest
Input bundle: context parameters + effective date.
### ComponentTree
Hierarchical structure of components that defines a complete calculation.

## Operations
### calculate, resolveApplicability, resolveValidity, composeComponents

## Integration Points
### Consumers (OHS)
- Product Catalog, Emission Factor Management, Compliance & Audit — all consume generic calculation API
