# Emission Factor Management - Ubiquitous Language

## Module Description
Manages emission factors, their audit trail, update governance, and protocol compliance. Specific to greenhouse gas accounting regulations. Knows about auditors, GHG Protocol, scopes 1/2/3, and regulatory versioning.

## Core Domain Terms
### WspolczynnikEmisji (Emission Factor)
A numeric factor (kg CO2 per unit) used in footprint calculations. Has source, version, and validity period.
### Zakres (Scope)
GHG Protocol classification: SCOPE_1 (direct emissions), SCOPE_2 (energy indirect), SCOPE_3 (value chain). Subcategories: SCOPE_3_TRANSPORT, SCOPE_3_UPSTREAM, SCOPE_3_DOWNSTREAM.
### Audytor (Auditor)
A person authorized to approve emission factor changes.
### ProtokolGHG (GHG Protocol)
The Greenhouse Gas Protocol standard. Versions: GHG_PROTOCOL_V1, GHG_PROTOCOL_V2, GHG_PROTOCOL_V3.
### LimitAktualizacji (Update Limit)
Governance rule: emission factors can be updated at most 4 times per year.
### SlownikEmisji (Emission Dictionary)
Master list of all approved emission factors with audit trail.

## Operations
### zaktualizujWspolczynnik(faktorId, nowaWartosc, audytorId, uzasadnienie)
Update an emission factor — requires auditor approval, checks update limit.
### zablokujWspolczynnik(faktorId)
Lock an emission factor — prevents further changes until next audit cycle.

## Domain Events
### WspolczynnikZaktualizowany
Published when emission factor changes. Contains: faktorId, stara, nowa, audytorId, wersjaProtokolu.
### WspolczynnikZablokowany
Published when emission factor is locked. Contains: faktorId, audytorId.

## Integration Points
### Footprint Calculation Engine (OHS — Emission Factor Mgmt consumes Engine's generic API)
- Provides emission factors as Components to `calculate()`
- Maps: zakres -> ContextParameter, wersjaProtokolu -> ContextParameter
- Sets: adjustmentFactor from protocol-specific coefficients
- Sets: regulatoryPrecision based on GHG Protocol version requirements
