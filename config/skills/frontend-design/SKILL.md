---
name: frontend-design
version: 1.0.0
description: "Anti-mediocre frontend output. Forces intentional design (typography scale, spacing rhythm, semantic color, motion grammar, identity-aware components) instead of generic gradients + Bootstrap-grade UI. Auto-activate on 'UI', 'component', 'page', 'screen', 'pantalla', 'styled', 'tailwind', 'shadcn', 'design system', or when writing JSX/TSX/Vue/Svelte without a token reference."
triggers:
  [
    UI,
    component,
    page,
    screen,
    pantalla,
    styled,
    tailwind,
    shadcn,
    "design system",
    typography,
    spacing,
    "design tokens",
  ]
---

# Frontend-Design — anti-mediocre UI output

> Sin esto, los LLMs generan: gradients morados, "modern" tipografía Inter,
> rounded-2xl en todo, mismo card layout en cada página, animaciones
> default. Esta skill **fuerza intención** antes de generar markup.

## Por qué existe

La queja #1 sobre output frontend de LLMs:

> "Claude makes everything look the same — gradient + Inter + rounded + shadow."

Causa raíz: sin guard-rails, el modelo elige defaults populares de su training.
Esos defaults son "OK" pero no son **el sistema** del proyecto.

Esta skill es el guard-rail.

## Cuándo activarte

| Señal                                                                        | Acción                              |
| ---------------------------------------------------------------------------- | ----------------------------------- |
| Operador pide UI / componente / pantalla nueva                               | Activar                             |
| Editás JSX/TSX/Vue/Svelte sin un token reference visible                     | Activar                             |
| El proyecto NO tiene `design-tokens.json` / `tailwind.config.*` / `theme.ts` | Auto-trigger + setup propose        |
| El proyecto SÍ los tiene                                                     | Activar + cargar tokens primero     |
| Surgical edit (1 prop CSS)                                                   | NO — usar SCAN MODE con `@designer` |
| Backend / API / no-UI                                                        | NO                                  |

## Workflow (5 pasos antes de escribir markup)

### 1. Token discovery (no skip)

Antes de cualquier `<div>`, buscá:

```bash
fd -e json -e ts -e js 'tailwind|tokens|theme|design' --max-depth 3
```

- Si encontrás → cargá `colors`, `spacing`, `fontFamily`, `fontSize`, `borderRadius`. **Usalos**, no inventes valores.
- Si no encontrás → propuesta abajo de "minimal token set". Operador aprueba o pasa los tokens existentes.

### 2. Component contract (declarado, no asumido)

Antes de generar el componente, decí en una frase:

```
<Button>: variants=(primary, secondary, ghost, destructive)
          sizes=(sm, md, lg)
          states=(default, hover, active, focus-visible, disabled, loading)
          a11y=(role=button, aria-disabled cuando loading, aria-busy)
          tokens=(--color-bg-{variant}, --space-{size}, --radius-md)
```

Esto es 30 tokens. El que no lo declara entrega un componente sin estados de loading / focus-visible / disabled, que es el 80% de los componentes mal escritos.

### 3. Identity check (anti-genérico)

Antes de aceptar tu propio output, revisá los 5 sospechosos:

| Anti-pattern                     | Síntoma                                               | Reemplazo                                                                                 |
| -------------------------------- | ----------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Gradient morado/blue por default | `bg-gradient-to-r from-purple-500 to-blue-500`        | Semantic color tokens del sistema. Si no hay sistema → un solo brand color, sin gradient. |
| Fuente Inter sin razón           | `font-family: Inter, ui-sans-serif` en el primer file | Usar la del sistema. Si no hay → un sans + un serif de display, justificado.              |
| `rounded-2xl` en todo            | "Modern look" sin contexto                            | Token de radio: `--radius-sm/md/lg`. Aplicar el más chico que comunique la intención.     |
| Mismo card layout repetido       | 12 cards con shadow-lg + p-6 + rounded                | Atomic Design: si lo hacés 2 veces → componente. 3ª → con variants.                       |
| Animaciones default              | `transition-all duration-200` everywhere              | Motion grammar: easings + durations tokens. `transition-all` es performance debt.         |

Si tu output tiene >2 de esos → reescribí.

### 4. State coverage

Toda UI tiene **6 estados mínimos**, no solo el "happy path":

```
default · hover · focus-visible · active · disabled · loading
```

Y si la pantalla muestra data:

```
empty · loading · error · offline · partial · stale
```

**Si no especificaste todos los relevantes, no terminaste el componente.**

### 5. Output ritual

Tu entregable debe:

- Usar tokens (no `#3b82f6` literal).
- Tener focus-visible explícito (`outline: 2px solid var(--ring)` o `focus-visible:ring-2`).
- Touch targets ≥ 44×44 en touch surfaces.
- Contrast ratio ≥ 4.5:1 (AA) — chequeable contra los tokens elegidos.
- `prefers-reduced-motion` honrado en transiciones > 200ms.
- Tipografía con line-height + letter-spacing definidos (no defaults del browser).

## Minimal token set (cuando el proyecto no tiene)

Propuesta que el operador acepta o reemplaza:

```ts
// design-tokens.ts
export const tokens = {
  color: {
    // semantic, not literal
    bg: { canvas: "#fafafa", surface: "#ffffff", muted: "#f4f4f5" },
    fg: { default: "#18181b", muted: "#71717a", subtle: "#a1a1aa" },
    border: { default: "#e4e4e7", strong: "#d4d4d8" },
    brand: { default: "#0f172a", hover: "#1e293b", subtle: "#f1f5f9" },
    // states (used everywhere)
    danger: "#dc2626",
    warning: "#d97706",
    success: "#16a34a",
    info: "#2563eb",
  },
  space: {
    0: "0",
    1: "4px",
    2: "8px",
    3: "12px",
    4: "16px",
    6: "24px",
    8: "32px",
    12: "48px",
  },
  radius: { sm: "4px", md: "6px", lg: "8px", xl: "12px", full: "9999px" },
  font: {
    sans: 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif',
    mono: 'ui-monospace, "SF Mono", Menlo, monospace',
    size: {
      xs: "12px",
      sm: "14px",
      base: "16px",
      lg: "18px",
      xl: "20px",
      "2xl": "24px",
      "3xl": "30px",
    },
  },
  motion: {
    fast: "150ms cubic-bezier(0.4, 0, 0.2, 1)",
    base: "200ms cubic-bezier(0.4, 0, 0.2, 1)",
    slow: "300ms cubic-bezier(0.4, 0, 0.2, 1)",
  },
  shadow: {
    sm: "0 1px 2px 0 rgb(0 0 0 / 0.05)",
    md: "0 4px 6px -1px rgb(0 0 0 / 0.1)",
    lg: "0 10px 15px -3px rgb(0 0 0 / 0.1)",
  },
};
```

Honest defaults: system-ui (no Inter), zinc/slate neutrals (no blue tint), 4px space base, semantic colors. **No gradients.**

## Combinación con `@designer` agent

| Caso                                                   | Tool                                            |
| ------------------------------------------------------ | ----------------------------------------------- |
| Skill activa proactivamente al escribir UI             | Esta skill (cheap, fast).                       |
| Necesitás review profundo (a11y, atomic design, brand) | `@designer` agent.                              |
| 1 prop CSS surgical edit                               | `[SCAN MODE] @designer`.                        |
| Diseñar el sistema entero from scratch                 | `@designer` agent + ADR.                        |
| Dudás entre dos approaches visuales                    | `@designer` con confidence tagging (v4.2 §6.2). |

La skill es la **primera línea de defensa**. El agente es la **segunda**.

## Anti-patterns

| Mal                                                         | Bien                                                                              |
| ----------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `<div className="...50 utility classes...">` sin componente | Si > 6 clases, extrae a componente named.                                         |
| `style={{ marginTop: '17px' }}`                             | Token: `space-4` (16px) o `space-5` (20px). 17 es ruido.                          |
| `color: '#3b82f6'`                                          | `color: var(--color-brand)`. Cambio futuro = 1 línea.                             |
| Componente sin `loading` / `error` / `empty` props          | Estados son props, no afterthoughts.                                              |
| `transition-all`                                            | `transition-property: transform, opacity, background-color`. Listar lo que anima. |
| Animación sin reduce-motion                                 | `@media (prefers-reduced-motion: reduce) { animation: none; }`                    |
| Tipografía con solo `font-size`                             | Pareja: `font-size` + `line-height` + opcionalmente `letter-spacing`.             |

## Token economy

- Skill activation: ~150 tok (este metadata + body lazy-loaded).
- Token discovery: ~200 tok (1 grep + 1 read).
- ROI: el componente bien-tokenizado se reusa. Sin skill, cada pantalla nueva re-define los mismos colores hardcoded → re-tokenización debt = 5-20× más caro.

## Confidence (v4.2 §6.2)

Después de generar UI, cierra con:

```
confidence: high
why: usé tokens existentes, todos los estados cubiertos, contrast 4.5:1+ verificado contra el design-tokens.ts.
```

o

```
confidence: medium
why: no encontré design-tokens en el repo; usé el minimal-token-set propuesto. Operador puede reemplazar.
```
