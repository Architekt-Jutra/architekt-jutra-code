---
paths:
  - "src/main/java/**"
---

# JPA Entity Modeling

Applies to anything under `pl.devstyle.aj` that maps to a table.

## Structure

- Singular entity name, plural table name: `class Product` → `@Table(name = "products")`. Never `@Entity(name = ...)` — that changes JPQL.
- Extend `BaseEntity` (`id`, `createdAt`, `@Version updatedAt`). Don't override `getId()`. Don't add `@LastModifiedDate` next to `@Version` — Hibernate manages it.
- Declare the sequence on the entity: `@SequenceGenerator(name = "base_seq", sequenceName = "<singular>_seq", allocationSize = 1)`.
- Natural-key entities (`PluginDescriptor`) skip `BaseEntity` and declare `@Id` plus audit fields directly.
- Field access (annotations on fields), not property access.
- Lombok: `@Getter @Setter @NoArgsConstructor`. Never `@Data` or `@EqualsAndHashCode` — both generate identity semantics that break on managed entities.
- Don't make entity classes or methods `final` — it breaks proxying.

## Keys and identity

- `GenerationType.SEQUENCE` with `allocationSize = 1`. Never `IDENTITY` (disables JDBC batching), `TABLE`, or `AUTO`.
- `Long` for generated ids, not primitive `long` — null means "not yet persisted".
- `equals`/`hashCode` use the **business key** (`Product.sku`), never the `@Id` — the id changes during the entity lifecycle. If no natural key exists, add a `UUID businessKey`.

## Columns

- `@Column(nullable = false)` for required fields, `unique = true` for business keys — enforce at the database, not only in Java.
- `BigDecimal` for money (never `float`/`double`), `LocalDateTime` for timestamps, explicit `length` for strings.
- `@Enumerated(EnumType.STRING)` always. `ORDINAL` breaks the moment someone reorders the enum.
- JSONB columns: `@JdbcTypeCode(SqlTypes.JSON)` + `@Column(columnDefinition = "jsonb")`, as on `Product.pluginData`.
- Index foreign keys and columns used in WHERE/JOIN/ORDER BY via `@Table(indexes = ...)`, but don't over-index — every index costs on write.

## Relationships

- Everything `FetchType.LAZY`. `@OneToOne` and `@ManyToOne` default to EAGER — override them explicitly.
- `mappedBy` on the non-owning side. Omitting it silently creates a duplicate FK or a join table.
- Bidirectional `@OneToMany`: add a helper that sets both sides (`addOrder(order)` calls `order.setCustomer(this)`).
- `orphanRemoval = true` only when the child is meaningless without the parent.
- Cascade for composition (Order → OrderLine), not for independent entities (Order → Customer). Name the types you need — `{CascadeType.PERSIST, CascadeType.REMOVE}` — not `CascadeType.ALL`.
- Need extra fields on a many-to-many? Use an explicit join entity instead of `@ManyToMany`.

## Collections and value objects

- `Set<?>` by default — a `List` without `@OrderColumn` becomes a Bag with the worst performance profile. Use `List + @OrderColumn` only when order is part of the model.
- Initialize at the field: `private Set<Order> orders = new HashSet<>();`
- Return unmodifiable views from collection getters so mutation goes through the helper methods.
- Prefer primitives, enums, or `@ElementCollection` over a whole entity for simple value collections. Create an entity only when you need identity, lifecycle, or relationships.
- `@Embeddable` classes must implement `equals`/`hashCode` — without them Hibernate dirty-checks excessively. Use `@AttributeOverrides` for two embeddables of the same type.

## Module boundaries

Reference entities from another bounded context by **id**, not by association:

```java
// DON'T
@ManyToOne @JoinColumn(name = "company_id")
private Company company;

// DO
@Column(name = "company_id")
private CompanyId companyId;
```

This keeps modules decoupled and avoids dragging a foreign repository into the service. When you genuinely need the other side's data, go through a facade, or join in a jOOQ read query.
