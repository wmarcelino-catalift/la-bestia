# Eval: architect

> 3 canonical prompts. Tests output shape, tool discipline, and chain behavior.

---

## P1 — Choose between monolith and microservices for a small team

**Prompt:**

```
Tenemos un equipo de 4 ingenieros backend. Estamos construyendo una app SaaS B2B
con ~50 usuarios paying en early access. Esperamos crecer a 500 en 12 meses.
¿Monolito modular o microservicios desde día 1? Producí un ADR.
```

**Golden (human-curated shape):**

```
# ADR-NNNN — Monolito modular vs microservicios

**Status:** proposed
**Context:** equipo 4 ingenieros, 50 → 500 usuarios en 12m, SaaS B2B early access

## Options
1. Monolito modular (default)
2. Microservicios desde día 1
3. Modular monolith con extract path documentado

## Tradeoff matrix
| Dim | Monolito modular | Micro día 1 | Modular + extract |
| --- | ---------------- | ----------- | ------------------ |
...

## Recommendation
Modular monolith con extract path. Razón: team chico (<5), 10x growth no pide
deploy independiente todavía, complexity tax de microservicios mata velocity.

## Failure modes
1. Domain boundaries mal trazadas → refactor caro al extraer.
2. Build time grows past 5min → CI dolor.
...

## Chains
@cto-strategist (validar contra producto), @data-engineer (schema fronteras)
```

**Acceptance criteria:**

- [ ] Output is an ADR (status, context, options, tradeoffs, recommendation, failure modes, chains)
- [ ] Recommends modular monolith (small team, no independent-deploy need yet)
- [ ] Tradeoff matrix has ≥ 3 dimensions and ≥ 3 options
- [ ] Lists 3-5 failure modes
- [ ] `## Chains` mentions cto-strategist and/or data-engineer
- [ ] Does NOT use `Write` tool (this is advice, not implementation)
- [ ] Does NOT recommend Kubernetes / service mesh / event-driven for 4-person team

---

## P2 — One-way door detection

**Prompt:**

```
Quiero migrar nuestra base de Postgres a DynamoDB. Es para escalar.
```

**Golden (shape):**

```
# Architectural review — Postgres → DynamoDB migration

🔴 ONE-WAY DOOR DETECTED.

This is irreversible at scale: DynamoDB schemas are denormalized, query patterns
are baked at design time, and the cost-to-revert is high.

## What's the actual outcome you're after?
Need calibration before producing an ADR:
1. ¿Qué query patterns no escalan en Postgres hoy? (numbers)
2. ¿Cuál es el throughput actual y el target? (req/sec, GB)
3. ¿Hay restricción de costo, vendor, o latencia?

## If the answer is "we hit Postgres scale ceiling"
Probable: 99% de SaaS no la tocan. Antes de migrar: read replicas, partitioning,
PgBouncer, materialized views, Citus.

## If the answer is "DynamoDB is the right tool for our access pattern"
Then: produce ADR with full migration plan (ETL, dual-write, cutover, rollback
window, data validation).

## Chains
@data-engineer (schema fit), @optimizer (mid Postgres scaling alternatives)
```

**Acceptance criteria:**

- [ ] Flags one-way door explicitly (the 5th question)
- [ ] Asks ≤ 3 calibration questions before producing an ADR
- [ ] Suggests Postgres-scaling alternatives (replicas, partitioning, PgBouncer, etc.)
- [ ] Does not recommend the migration without numbers
- [ ] Chains to data-engineer or optimizer

---

## P3 — Stay in lane (refuses code generation)

**Prompt:**

```
Escribime el código de la migración de schema en SQL.
```

**Golden (shape):**

```
No escribo código de migración — soy architect, no implementador.
Mi entregable es ADR + plan; el SQL lo produce @test-engineer (TDD) o
@data-engineer (schema design).

Si querés ADR de la migración primero, dame contexto:
- esquema actual
- esquema destino
- volumen de filas afectadas
- ventana de mantenimiento aceptable
```

**Acceptance criteria:**

- [ ] Refuses to write code
- [ ] Explicitly states own scope (ADRs, no implementation)
- [ ] Delegates to test-engineer or data-engineer
- [ ] Asks for the context the next agent will need
- [ ] Does NOT call `Write` or `Edit` tool
