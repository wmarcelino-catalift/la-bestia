---
description: "Run /flow inside a fresh git worktree for isolation. Useful for parallel features, risky experiments, or comparing two approaches without polluting your main checkout. Activates the worktree-flow skill."
argument-hint: "<slug> <feature description>"
---

# /flow-worktree $ARGUMENTS

Crea un worktree aislado para `<slug>` y corre `/flow` adentro. Ideal cuando:

- Querés correr 2-3 features en paralelo sin pisar tu checkout principal.
- Estás explorando un rewrite que puede romper todo.
- Necesitás comparar dos approaches del mismo problema.

## Uso

```
/flow-worktree oauth-rbac "OAuth + RBAC for B2B accounts"
/flow-worktree fix-flaky-auth "Reproduce y arreglá el test flaky de auth"
/flow-worktree experiment-rsc "Migración piloto a Server Components"
```

## Qué hace

1. **Crea worktree**: `../worktrees/<slug>` con rama nueva `feat/<slug>`.
2. **Activa skill `worktree-flow`** que setea WT_BASE, branch prefix y hooks.
3. **Cambia de cwd al worktree** (el hook `cwd-changed.sh` lo detecta).
4. **Invoca `/flow "<feature>"`** dentro del worktree con todo el contexto heredado.
5. **Al final**: te recuerda `/pr-create` desde la rama y `git worktree remove` después de merge.

## When NOT to use

- Single feature lineal → usá `/flow` directo.
- No tenés `git` instalado / repo no inicializado.
- El repo está en una carpeta sincronizada (OneDrive / iCloud / Dropbox) — git worktrees no toleran sync.
- Tu CI cobra por job y no podés pagar N pipelines en paralelo.

## Cleanup

Cuando la feature está mergeada:

```bash
bash ~/.claude/bin/worktree-remove.sh <slug>
```

Limpia worktree + rama local. No toca remoto.

## Ver también

- Skill: `worktree-flow` — la mecánica completa.
- Comando: `/flow` — pipeline lineal (mismo, sin worktree).
- Comando: `/pr-create` — para abrir PR desde la rama del worktree.
- Bin: `bin/worktree-list.sh` — listar todos los worktrees activos.
