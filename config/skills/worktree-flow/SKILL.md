---
name: worktree-flow
version: 1.0.0
description: "Run /flow phases in isolated git worktrees so multiple features can run in parallel without polluting the main checkout. Each worktree is a real cheap branch on disk; cleanup is one command. Auto-trigger on 'worktree', 'parallel feature', 'isolate work', 'try without committing', or when /flow is invoked with --worktree flag."
triggers:
  [
    worktree,
    "parallel feature",
    "isolate work",
    "try without committing",
    "git worktree",
    "trabajar en paralelo",
  ]
---

# Worktree-Flow — paralelismo real con isolation

> Git worktrees son la herramienta correcta para correr varias features
> simultáneamente sin tocar tu checkout principal. La Bestia v4.2 las usa
> como sandbox para `/flow` cuando querés probar sin commit-and-pray.

## Por qué worktrees y no branches

| Branches                              | Worktrees                             |
| ------------------------------------- | ------------------------------------- |
| Un solo working dir                   | N working dirs sobre el mismo `.git/` |
| `git checkout` rota archivos          | Cada feature tiene su carpeta         |
| Stash+pop entre features              | Cero ceremonia                        |
| Si algo rompe el checkout, rompe todo | Aislado por carpeta                   |
| Caro en disco (clones)                | Casi gratis (un solo objects/)        |

## Cuándo invocarte

| Situación                                                    | Acción                                         |
| ------------------------------------------------------------ | ---------------------------------------------- |
| Tres features pequeñas que se pueden paralelizar             | `/flow-worktree` por cada una                  |
| Experimento riesgoso ("¿y si reescribimos…?")                | worktree → si rompe, `git worktree remove`     |
| Bug que requiere bisect en otra rama mientras seguís en main | worktree para el bisect                        |
| Comparar dos approaches del mismo feature                    | dos worktrees, dos `/flow` corriendo           |
| Una sola feature lineal                                      | NO — usá `/flow` normal. Worktree es overhead. |
| Cliente apurado, single-track                                | NO — branches normales.                        |

## Workflow (5 pasos)

### 1. Setup

```bash
# Desde el repo principal:
WT_BASE="${WT_BASE:-../worktrees}"
mkdir -p "$WT_BASE"
SLUG="$1"   # e.g. "oauth-rbac"
git worktree add "$WT_BASE/$SLUG" -b "feat/$SLUG"
cd "$WT_BASE/$SLUG"
```

Equivalente con la Bestia:

```bash
bash ~/.claude/bin/worktree-add.sh oauth-rbac
```

### 2. Run /flow inside the worktree

```bash
# CWD = $WT_BASE/$SLUG
claude
> /flow "OAuth + RBAC for B2B accounts"
```

El `cwd-changed.sh` hook detecta que cambiaste de proyecto y sugiere
`/onboard-project` si el worktree no tiene `memory/hot-context.md` (raro
porque hereda del repo principal — pero la verificación es deterministic).

### 3. Iterate sin tocar main

Mientras `/flow` corre en `oauth-rbac/`, podés tener otra terminal en
`payments/`, otra en `feedback-form/` — todas independientes.

### 4. Merge back

```bash
cd "$REPO_MAIN"
git merge feat/oauth-rbac          # o crear PR via /pr-create
```

### 5. Cleanup

```bash
git worktree remove "$WT_BASE/oauth-rbac"
git branch -d feat/oauth-rbac      # si ya está mergeada
```

Equivalente:

```bash
bash ~/.claude/bin/worktree-remove.sh oauth-rbac
```

## Combinación con la Bestia

| Componente                  | Comportamiento en worktree                                                                                                                       |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `inject-context.sh`         | Lee `memory/hot-context.md` del worktree (que es el mismo del repo).                                                                             |
| `restore-context.sh` (v4.2) | Igual. ADRs / patterns / lessons son compartidas — `memory/` apunta al mismo sitio.                                                              |
| `block-secrets.sh`          | Funciona idéntico — el hook no depende de la rama.                                                                                               |
| `route-prompt.sh`           | Igual.                                                                                                                                           |
| `log-agents.sh`             | Apunta a `<worktree>/.claude/logs/agents.jsonl` por default. Si querés un solo log centralizado, settá `CLAUDE_LOG_DIR=$REPO_MAIN/.claude/logs`. |
| `/onboard-project`          | NO correr en worktree — `memory/` ya existe en el repo principal.                                                                                |
| `/flow`                     | Corre normal. La diferencia está en el aislamiento de archivos, no en la lógica.                                                                 |

## Anti-patterns

| Mal                                      | Bien                                                                                        |
| ---------------------------------------- | ------------------------------------------------------------------------------------------- |
| Crear un worktree por cada commit        | Un worktree por feature de >2h.                                                             |
| Olvidar `git worktree remove`            | Listar con `git worktree list` cada semana.                                                 |
| Worktrees dentro del repo (`./wt/foo`)   | Afuera (`../worktrees/foo`) — evita que los formatters / ignores de un worktree pisen otro. |
| Editar el mismo archivo en dos worktrees | Las ramas son independientes — git lo permite — pero te vas a pelear en el merge.           |
| Borrar la carpeta a mano (`rm -rf`)      | `git worktree remove` mantiene el grafo de git limpio.                                      |

## Token economy

- Sin worktree, paralelizar 2 features te obliga a `/clear` + reload memoria → perdés todo el contexto cacheado.
- Con worktree: cada Claude Code session arranca en su carpeta, hot-context.md está local, ADRs/patterns compartidas. Cero recompute.
- ROI: ~30-40% ahorro en una semana con 2-3 features simultáneas.

## Cuándo NO usar worktrees

- Estás solo, una feature por vez → branches normales son más simples.
- Trabajás en una carpeta de OneDrive / Dropbox / iCloud → la sincronización rompe el `.git/worktrees/<name>`. Usá un repo en disco local fuera del sync folder.
- Tu CI corre en cada push y el costo de jobs paralelos es alto → considerá `--draft` PRs en vez de N worktrees pushed.

## Helpers (v4.2)

Bestia ships con:

- `bin/worktree-add.sh <slug>` — crea `../worktrees/<slug>` con rama `feat/<slug>`.
- `bin/worktree-remove.sh <slug>` — limpia worktree + rama.
- `bin/worktree-list.sh` — lista worktrees con su feature, último commit y status (uncommitted yes/no).

Todos respetan `WT_BASE` y `WT_BRANCH_PREFIX` env vars.
