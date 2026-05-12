package calculationengine;

public enum ComponentType {
    MROZONKI_TRANSPORT,      // ❌ Product Catalog language (frozen food transport)
    NABIAJ_PRZECHOWYWANIE,   // ❌ Product Catalog language (dairy storage)
    SCOPE_1_DIRECT,          // ❌ Emission Factor Mgmt language (GHG scope 1)
    SCOPE_3_LOGISTICS,       // ❌ Emission Factor Mgmt language (GHG scope 3)
    GHG_PROTOCOL_FACTOR,     // ❌ Emission Factor Mgmt language (protocol-specific)
    ELEKTRONIKA_PACKAGING,   // ❌ Product Catalog language (electronics packaging)
    BASE_EMISSION,           // ✅ Calculation Engine's own language
    SURCHARGE,               // ✅ Calculation Engine's own language
    ADJUSTMENT               // ✅ Calculation Engine's own language
}
