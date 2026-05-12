# Emission Factor Management - Ubiquitous Language

## Module Description
Manages emission factors, auditors, GHG Protocol compliance. Factors updated max 4x/year with auditor locking.

## Core Domain Terms
### EmissionFactor, GhgScope, Auditor, ProtocolVersion, FactorCategory, AuditLock

## Domain Events
### EmissionFactorUpdated
Factor value changed. Contains: factorId, ghgScope, auditorId, protocolVersion, newValue, effectiveDate.
### AuditorLockedCategory
Auditor locked a category for review. Contains: auditorId, categoryId, lockExpiry.

## Integration Points
### Footprint Calculation Engine (publishes events — engine may react)
- Publishes EmissionFactorUpdated when factors change
- Publishes AuditorLockedCategory when categories are locked
