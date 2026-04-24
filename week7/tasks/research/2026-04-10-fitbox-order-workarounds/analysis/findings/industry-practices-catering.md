# Industry Practices: Catering Dietetyczny / Meal Prep

## Research Focus

Jak systemy cateringowe i meal-prep radza sobie z obejsciami zamowien: cutoff rules, forcing functions, walidacje, order amendment workflows.

**Layers**: Big Picture, Modeling

---

## 1. Order Cutoff Policies -- Meal Prep / Diet Delivery Companies

### 1.1 Factor (HelloFresh Group)

**Cutoff**: 11:59 PM CT, 5 days before delivery.

- All modifications (meal swaps, skip, cancel, change box size, change delivery day) must be made before weekly cutoff.
- After cutoff: order is locked -- no changes, no cancellation, charge proceeds.
- Notifications: Factor sends email reminders before cutoff deadline.
- Pause/skip: available up to 6 weeks in advance, preserves promo discounts and delivery preferences.
- Self-service: all changes via app or website, no need to call.

**Evidence**: Factor website (https://www.factor75.com/about/how-it-works), Healthline review (https://www.healthline.com/nutrition/factor-75), Mealfan cancel guide (https://mealfan.com/how-to-cancel-factor-75/).

**Confidence**: High (90%) -- multiple sources confirm 5-day cutoff and self-service model.

### 1.2 HelloFresh

**Cutoff**: 11:59 PM PST, 5 days before delivery.

- Same 5-day window as Factor (both owned by HelloFresh Group).
- Cutoff enforced to allow supplier notification and procurement planning.
- After cutoff: order is locked, no modifications possible.

**Evidence**: HelloFresh support article (https://support.hellofresh.com/hc/en-us/articles/115012777767-Deadline-for-making-changes-).

**Confidence**: High (95%) -- direct from official support documentation.

### 1.3 CookUnity

**Cutoff**: Varies by location, 4-6 days before delivery. All orders processed at noon on cutoff day.

- Before cutoff: free to change meals, skip, or cancel.
- After cutoff: no changes, no cancellations.
- Notification: text and email 24 hours before cutoff time.
- Cutoff time visible on Orders page in account dashboard.

**Evidence**: CookUnity support (https://support.cookunity.com/hc/en-us/articles/27915042183451-When-is-my-cut-off-time), CookUnity support (https://support.cookunity.com/hc/en-us/articles/27675035253659-Can-I-cancel-an-order-after-it-s-been-charged).

**Confidence**: High (90%) -- direct from official support.

### 1.4 Trifecta Nutrition

**Cutoff**: Friday 11:59 PM PT, one week before delivery.

- 7-day modification window -- the longest among surveyed companies.
- Changes made < 7 days in advance take effect the following week.
- Skip up to 4 weeks with 7 days' notice.
- After cutoff: order is already processing, cannot be cancelled.
- Support available 7 days/week 8 AM - 5 PM PT for edge cases.

**Evidence**: Trifecta FAQ (https://www.trifectanutrition.com/ask-us-anything/how-do-i-update-my-trifecta-order), Mealdeliverypro (https://mealdeliverypro.com/how-to-cancel-trifecta/).

**Confidence**: High (90%) -- direct from official FAQ.

### 1.5 Polish Diet Box Catering (dieta pudelkowa)

**Cutoff example (DietaPudelkowa.pl)**: 10:00 PM, 2 days before delivery (order by Monday 10 PM for Wednesday delivery).

- Polish diet catering typically uses shorter cutoff windows (24-48h) than US subscription services (5-7 days).
- Customer panels allow: changing delivery day, changing address, pausing, managing diet type.
- More operational flexibility but higher risk of late changes affecting production.

**Evidence**: DietaPudelkowa.pl, Dietly.pl, Foodango.pl search results.

**Confidence**: Medium (70%) -- aggregated from search result snippets, not deep-dive into individual companies.

### Summary Table: Cutoff Policies

| Company | Cutoff Window | Enforcement | Self-Service | Notification |
|---------|--------------|-------------|-------------|-------------|
| Factor | 5 days | Hard lock | App + web | Email |
| HelloFresh | 5 days | Hard lock | Web | Email |
| CookUnity | 4-6 days (varies) | Hard lock at noon | Web | Text + email 24h before |
| Trifecta | 7 days | Hard lock | Web | Via account |
| Polish diet catering | 1-2 days | Varies | Customer panel | Varies |

---

## 2. Order Amendment Workflows and Forcing Functions

### 2.1 Olo Platform -- Catering Capacity Management

Olo (catering management platform for restaurants) provides the most documented set of forcing functions:

**Lead Time Rules (Forcing Functions)**:
- Channel-level baseline: e.g., "All catering orders require 24 hours notice."
- Menu item-level granularity: different lead times per item (ribs = 48h, wings = shorter).
- Revenue-based rules: orders over $500 require longer lead time.
- Seasonal adjustments: extended windows for Thanksgiving, Valentine's Day, sports events.

**Order Throttling**:
- Limits number of orders per time window (e.g., max 10 catering orders during lunch rush).
- When exceeded: customers automatically offered alternative pickup times.
- This is a capacity-based forcing function -- prevents kitchen overload.

**Delayed Firing Window**:
- After order placement, system delays firing to kitchen until later (e.g., 11 PM night before).
- Creates amendment window: customer can call with changes before production starts.
- Avoids "refund and recreate" workflow for simple modifications.

**VIP Override**:
- Managers can override lead time settings for critical accounts via Switchboard tool.
- Intentional exception: "when you know you have the staff and ingredients on hand."
- Key principle: exceptions should be intentional, not forced.

**Evidence**: Olo blog (https://www.olo.com/blog/the-catering-capacity-crunch-best-practices-to-prevent-kitchen-overload).

**Confidence**: High (95%) -- detailed article from the platform vendor.

### 2.2 CaterZen -- Real-Time Order Updates

**Same-Day Modification Handling**:
- "If a client calls the morning of to cut their headcount by 20, the software automatically updates kitchen prep sheets, delivery manifests, and invoices."
- Real-time cascade: one change propagates to all downstream documents.
- This is the opposite of a cutoff -- allows changes until production, but automates the cascade to prevent inconsistencies.

**Client Preference Storage**:
- Per-client dietary preferences stored in profiles (e.g., "no onions ever").
- Applied automatically to new orders.
- Reduces need for per-order customization requests.

**Blackout Dates**:
- Capacity management via blackout dates -- blocks orders on overbooked dates.
- Prevents system from accepting orders it cannot fulfill.

**Evidence**: CaterZen FAQ (https://www.caterzen.com/blog/ultimate-catering-software-faq).

**Confidence**: High (85%) -- from vendor documentation.

### 2.3 Flex Catering -- Meal Prep Software

**Cutoff Settings**:
- Configurable cutoff times and closure periods per customer/company.
- Per-customer pricing and delivery rules (free delivery thresholds, company discounts).

**Production Documents**:
- Auto-generates: prep sheets, production lists, worksheets, packing summaries.
- Customizable with filters and selectable columns.
- Exportable to Excel/PDF for kitchen, packing, and delivery teams.
- Ingredient quantity breakdowns to ensure accuracy and reduce waste.

**Evidence**: Flex Catering (https://www.flexcateringhq.com/meal-prep-software/).

**Confidence**: Medium (75%) -- feature lists from marketing page, not operational documentation.

---

## 3. Production Planning vs. Late Changes

### 3.1 Production Sheet Systems

**Olo Production Sheets**:
- Automatically multiplies recipes across all incoming orders.
- Generates consolidated prep lists: total ingredients across all orders OR broken down per individual order.
- Supports two kitchen workflows: batch prep (aggregate) vs. per-order prep (individual).
- Dual-level reporting: aggregate for procurement, individual for day-of execution.

**General Pattern**: Production sheets are the "point of truth" for the kitchen. Once printed/locked, any change that bypasses the production sheet creates a shadow process.

**Relevance to FitBox**: Tomek's problem (listy produkcyjne drukowane o 3:30, zmiany z arkusza wchodza po wydrukowaniu) is a classic "production lock vs. late amendment" conflict. Industry solutions use delayed firing windows (Olo) or real-time cascade updates (CaterZen) to prevent this split.

**Confidence**: High (90%).

### 3.2 Batch Production Scheduling

CloudKitchens recommends:
- Batch production schedules outlining: prep timelines, cooking schedules based on delivery times, packing deadlines, delivery route planning.
- 24-48 hour pre-event reconfirmation to catch last-minute changes.
- Approach: advance communication rather than strict cutoffs, giving kitchen visibility into potential modifications.

**Evidence**: CloudKitchens blog (https://cloudkitchens.com/blog/strategies-to-handle-high-volume-catering-orders/).

**Confidence**: Medium (75%) -- general best practices, not specific to diet catering.

---

## 4. Allergen Management Systems

### 4.1 Industry Standard: Major Allergen Tracking

**HelloFresh Model**:
- Nutrition team with dietitians reviews every ingredient for top 8 allergens (wheat, milk, soy, eggs, tree nuts, peanuts, fish, shellfish).
- Allergen information posted on website next to meal choice, with specific ingredient called out.
- Critical limitation: "small chance of cross-contamination -- cannot guarantee allergen-free."
- Shared kitchen facilities: suitable for preference, not for severe allergy/celiac.

**Dedicated Facility Model**:
- Some services use dedicated allergen-free facilities (separate production lines).
- Eliminates cross-contamination risk -- required for celiac disease.
- Industry distinction: celiac (medical, < 20ppm gluten) vs. gluten preference (lifestyle choice).

**Evidence**: HelloFresh support (https://support.hellofresh.com/hc/en-us/articles/115008621547-I-have-an-allergy-What-do-I-do-), Beyond Celiac (https://www.beyondceliac.org/gluten-free-diet/food-safety/), GlutenDude (https://glutendude.com/gluten-free-meal-delivery-services/).

**Confidence**: High (90%).

### 4.2 Celiac vs. Preference Distinction

**Critical industry finding**: The distinction between celiac disease (autoimmune, medically dangerous) and gluten preference (lifestyle) requires different operational protocols:

| Level | Condition | Required Protocol | Kitchen Impact |
|-------|-----------|-------------------|---------------|
| Medical | Celiac disease, anaphylaxis | Dedicated facility or production line, < 20ppm verification | Separate prep area, dedicated tools, independent validation |
| Preference | Gluten-free lifestyle, mild intolerance | Clear ingredient labeling, reasonable cross-contamination controls | Standard kitchen with labeling |

**Relevance to FitBox**: Tomek's over-treatment problem (all gluten-free treated as celiac = extra hour daily) is a known industry challenge. The solution is a tiered allergen classification system that distinguishes severity levels and applies proportional protocols.

**Confidence**: High (85%) -- multiple medical/industry sources confirm the distinction.

### 4.3 Software-Based Allergen Tracking

**CertiStar**: Processes 170+ food allergens (not just top 8/14). Searchable menus for any allergen combination.

**EveryBite SmartMenu**: Implemented by 50 restaurant brands across 4,000+ US locations. Diners personalize menu by filtering specific allergens.

**CaterZen**: Per-client allergen profiles stored permanently. Applied automatically to every new order.

**Pattern**: Modern systems store allergen data at the client profile level, not the order level. This prevents the "forgot to mention allergy" problem.

**Evidence**: CertiStar (https://certistar.com/), AllergyMenu.app (https://allergymenu.app/).

**Confidence**: Medium (75%) -- from marketing materials.

---

## 5. Delivery Route Management

### 5.1 Dynamic Route Reassignment

Modern meal delivery logistics software (Upper, Onfleet, Route4Me) supports:
- **Real-time route recalculation**: when disruptions occur, routes are automatically resequenced.
- **Driver reassignment**: orders reassigned based on proximity and capacity.
- **Last-minute stop changes**: add/remove stops, software recalculates and optimizes.

**Key principle**: Route changes are handled through the system, not outside it. The software is designed to accommodate changes rather than force drivers to work around rigid routes.

**Relevance to FitBox**: Marek's problem (kierowcy zamieniaja sie trasami na parkingu, system pokazuje innego kierowce) is a symptom of a rigid routing system that doesn't support driver reassignment. Modern systems make route swaps a system-level operation, preserving data integrity.

**Evidence**: Upper (https://www.upperinc.com/businesses/healthy-meal-delivery-planning-route-optimization-app-software/), Onfleet (https://onfleet.com/).

**Confidence**: Medium (75%) -- from software vendor marketing, not operational case studies.

### 5.2 The Meal Delivery Routing Problem

Academic research highlights meal delivery as "the ultimate challenge in last mile logistics":
- Typical order expected within 1 hour, within minutes of food becoming ready.
- Reduces consolidation opportunities.
- Requires more vehicles operating simultaneously.

This creates pressure on drivers to optimize informally (route swaps, shortcuts) when the system doesn't provide adequate flexibility.

**Evidence**: Optimization Online paper (https://optimization-online.org/wp-content/uploads/2018/04/6571.pdf).

**Confidence**: Medium (70%) -- academic paper, may not reflect current practice.

---

## 6. Regulatory Context

### 6.1 FDA Food Traceability Final Rule (January 2026)

New US regulation mandates:
- Digital records tracing every ingredient to source.
- Seamless integration of temperature logs, delivery confirmations, audit trails.
- Clear allergen controls.

**Relevance**: Manual processes (Google Sheets, WhatsApp) will not meet regulatory traceability requirements. System-based allergen tracking becomes a compliance requirement, not just a best practice.

**Evidence**: FDA regulation, referenced in Optimum7 blog (https://www.optimum7.com/blog/how-to-successfully-introduce-and-market-a-meal-kit-delivery-subscription.html).

**Confidence**: Medium (70%) -- regulation confirmed but applicability to Polish market needs verification.

---

## 7. Key Patterns and Forcing Functions -- Summary

### 7.1 Forcing Functions Taxonomy

| Forcing Function | Mechanism | Prevents | Used By |
|-----------------|-----------|----------|---------|
| **Hard cutoff** | System locks orders N days before delivery | Late modifications bypassing production planning | Factor, HelloFresh, CookUnity, Trifecta |
| **Order throttling** | Limits orders per time window | Kitchen overload | Olo |
| **Revenue-based lead time** | Larger orders require more notice | Complex orders placed last-minute | Olo |
| **Delayed firing** | Order accepted but not sent to kitchen until later | Unnecessary "refund and recreate" for simple changes | Olo |
| **Blackout dates** | Blocks orders on specific dates | Over-commitment on peak days | CaterZen |
| **Per-item lead time** | Different prep requirements per menu item | Specialty items ordered with insufficient prep time | Olo |
| **Client profile allergens** | Allergens stored at profile level, auto-applied | Per-order allergen omissions | CaterZen, CertiStar |
| **Dynamic route reassignment** | System-level driver swap | Informal parking-lot route swaps | Upper, Onfleet |
| **Tiered allergen classification** | Medical vs. preference distinction | Over-treatment (celiac protocol for preferences) | Industry standard (not universally implemented) |

### 7.2 Anti-Patterns (What Causes Workarounds)

| Anti-Pattern | Symptom | Root Cause |
|-------------|---------|-----------|
| Rigid cutoff without amendment window | Staff bypass system via side channels (Google Sheets, WhatsApp) | No "delayed firing" or grace period between order acceptance and production lock |
| Single-tier allergen handling | Over-treatment (all restrictions treated as severe) or under-treatment (all treated as preference) | No severity classification in allergen data model |
| Print-and-forget production lists | Changes after print are invisible to kitchen | No real-time cascade from order changes to production documents |
| Static routing without driver flexibility | Drivers swap routes informally, system data becomes stale | Routing system doesn't support real-time reassignment |
| Per-order dietary data (not profile-based) | Repeat customers must re-specify allergies; errors on omission | Allergen data not linked to customer identity |

---

## Rejected Information

| # | Information | Source | Rejection Reason | Re-include If |
|---|------------|--------|-----------------|---------------|
| 1 | Detailed comparison of meal prep service pricing and nutritional value | Revgear, Mealfan, CleanEatzKitchen | Pricing/nutrition comparison -- not related to order management or workarounds | Scope expanded to competitive analysis |
| 2 | FDA 2026 employer meal deduction tax rules | UHY, CRI&G | Tax regulation, not food safety or order management | Scope includes financial/tax implications |
| 3 | Meal delivery service subscription marketing strategies | Optimum7 | Marketing focus, not operational workflow | Scope includes go-to-market strategy |
| 4 | Specific meal kit recipes and dietary plan details | Various meal kit review sites | Product content, not process/system | Scope includes product design |

---

## Actor Relevance

| Actor | Relevance | Key Takeaway |
|-------|-----------|--------------|
| Monika (Obsluga klienta) | High | Branza stosuje hard cutoff (5-7 dni) z self-service -- klient sam zmienia zamowienie przez app/web, nie dzwoni do obslugi. To eliminuje 15-20 dziennych zmian przez telefon. |
| Tomek (Szef kuchni) | High | Olo "delayed firing" rozwiazuje problem FitBox: zamowienie przyjete, ale nie wyslane do kuchni az do momentu produkcji. Zmiany przed firing window nie psuja listy produkcyjnej. CaterZen kaskadowo aktualizuje prep sheets w real-time. |
| Kasia (Dietetyczka) | High | Branza rozroznia celiac (medyczny, < 20ppm) vs preferencja (lifestyle). Profile alergenowe na poziomie klienta (nie zamowienia) eliminuja ryzyko pominiecia. CertiStar obsluguje 170+ alergenow. |
| Marek (Logistyka) | High | Nowoczesne systemy (Upper, Onfleet) wspieraja reassignment kierowcow na poziomie systemu -- zamiany tras to operacja systemowa, nie parkingowa. Real-time rekalkulacja tras. |
| Agnieszka (Wlascicielka) | High | Wzorzec branzowy: forcing functions (hard cutoff + delayed firing + profile allergens + dynamic routing) eliminuja potrzebe obejsc. Regulacja FDA 2026 wymaga cyfrowej trasowalnosci -- reczne procesy (arkusze, WhatsApp) nie spelnia wymagan. |
