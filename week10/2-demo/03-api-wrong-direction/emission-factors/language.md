# Emission Factor Management - Ubiquitous Language

## Module Description
Manages emission factors, scopes (Scope 1/2/3), auditors, GHG Protocol compliance. Knows about factor sources, measurement methodologies, and regulatory frameworks.

## Core Domain Terms
### WskaznikEmisji (EmissionFactor), WskaznikId, Zakres (Scope), Audytor (Auditor), ProtocolGHG, ZrodloWskaznika (FactorSource)

## Operations
### getFactorForCategory(kategoria)
Get emission factor for a specific product category.
### przeliczWskaznik(factorId, methodology)
Recalculate factor using a different methodology.

## Integration Points
### Footprint Calculation Engine (OHS — Emission Factors consumed by Calculation Engine)
- Calculation Engine queries factors through its own internal resolution
