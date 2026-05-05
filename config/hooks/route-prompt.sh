#!/usr/bin/env bash
# UserPromptSubmit hook — suggest a subagent or skill based on prompt keywords.
# v2.0: 12 agents (strategist, security, designer merged from v1.x duplicates).
# Agents: strategist, architect, mentor, test-engineer, code-reviewer, debugger,
#         security, optimizer, devops, tech-writer, designer, data-engineer.

set -u

PROMPT="${CLAUDE_USER_PROMPT:-}"
[ -z "$PROMPT" ] && exit 0

P=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

ROUTE=""
case "$P" in
  # ── Skills FIRST (override broader agent matches) ────────────────────────
  # `flow` / `pipeline-for-feature` outranks devops's broad `*pipeline*`.
  *flow*|*"full feature"*|*"double diamond"*|*"build feature"*)
    ROUTE="flow-feature (skill — try /flow)" ;;

  # ── Architecture / system design / ADRs (before strategy — more specific)
  *arquitectura*|*architecture*|*diseño*|*tradeoff*|*"vs "*|*patrón*|*escalabilidad*|\
  *adr*|*"cross-module"*|*"event-driven"*|*microservices*|*cqrs*|*saga*|\
  *"system design"*|*"distributed"*|*kafka*|*workflow*)
    ROUTE="architect" ;;

  # ── Strategy / product / business ────────────────────────────────────────
  # NOTE: dropped naked `*idea*` — matched "ideal" / "idealmente" too broadly.
  # Use space-padded variants below.
  *" idea "*|*" idea,"*|*" idea."*|*" idea:"*|*"feature nuevo"*|*producto*|\
  *negocio*|*estrategia*|*roadmap*|*priorizar*|*decisión*|*decision*|\
  *"should i use"*|*"should we"*|*"build vs buy"*|*"comprar vs construir"*|\
  *rice*|*okr*|*kpi*|*"unit economics"*|*"jobs to be done"*|*jtbd*|*pricing*|\
  *"go to market"*|*pmf*|*"pr-faq"*|*"working backwards"*)
    ROUTE="strategist" ;;

  # ── Adversarial review / decision validator ──────────────────────────────
  # Removed `*"should i"*` (too broad — see strategist's "should i use").
  *"pre-mortem"*|*"second opinion"*|*"devil's advocate"*|*"abogado del diablo"*|\
  *"one-way door"*|*"stress test"*|*"is this right"*|*"review my plan"*)
    ROUTE="mentor" ;;

  # ── Security / auth / payments / threat models ───────────────────────────
  *auth*|*login*|*password*|*payment*|*pago*|*secret*|*token*|*owasp*|*permission*|\
  *csrf*|*xss*|*"sql injection"*|*ssrf*|*idor*|*pii*|*phi*|*pci*|*"threat model"*|\
  *gdpr*|*hipaa*|*"zero trust"*|*"least privilege"*)
    ROUTE="security" ;;

  # ── Debugging / errors / bugs ────────────────────────────────────────────
  *bug*|*"no funciona"*|*rompe*|*crash*|*fail*|*error*|*broken*|*"stack trace"*|\
  *"no carga"*|*"no aparece"*|*"no se ve"*|*flaky*|*intermittent*|\
  *"5-whys"*|*"root cause"*|*regression*)
    ROUTE="debugger" ;;

  # ── Implementation / TDD / tests ─────────────────────────────────────────
  *implementar*|*"crear feature"*|*tdd*|*"red green refactor"*|*test*|*coverage*|\
  *"agrega "*|*"add "*|*"crea un"*|*build*|*"unit test"*|*"integration test"*|\
  *e2e*|*fixture*|*mock*)
    ROUTE="test-engineer" ;;

  # ── Code review (post-change) ────────────────────────────────────────────
  *review*|*"check this"*|*revisá*|*"revisa el código"*|*"revisa este"*|*solid*|\
  *"cognitive complexity"*|*"code smell"*|*"clean code"*)
    ROUTE="code-reviewer" ;;

  # ── Performance / optimization ───────────────────────────────────────────
  *slow*|*lento*|*performance*|*latency*|*throughput*|*"flame graph"*|*profile*|\
  *"memory leak"*|*"bundle size"*|*lcp*|*inp*|*ttfb*|*p99*|*"hot path"*|*optimize*|\
  *"web vitals"*)
    ROUTE="optimizer" ;;

  # ── DevOps / CI / deploy / infra ─────────────────────────────────────────
  *eas*|*"expo build"*|*"firebase deploy"*|*emulador*|*emulator*|*"github actions"*|\
  *" ci "*|*pipeline*|*"eas build"*|*"eas submit"*|*"eas update"*|*hosting*|\
  *"cloud functions"*|*deploy*|*docker*|*kubernetes*|*terraform*|*pulumi*|*iam*|\
  *"env vars"*|*fastlane*|*autoscale*|*observability*|*sre*|*"github action"*)
    ROUTE="devops" ;;

  # ── Tech writing / docs ──────────────────────────────────────────────────
  *docs*|*documentation*|*readme*|*"api docs"*|*changelog*|*"release notes"*|\
  *runbook*|*onboarding*|*"how-to"*|*tutorial*|*"developer guide"*)
    ROUTE="tech-writer" ;;

  # ── Design / UX / a11y / design systems ──────────────────────────────────
  *"ux "*|*" ui "*|*"design system"*|*"design token"*|*pantalla*|*modal*|\
  *accesibilidad*|*accessibility*|*wcag*|*responsive*|*"empty state"*|*"loading state"*|\
  *"error state"*|*figma*|*"brand"*|*component*)
    ROUTE="designer" ;;

  # ── Data / DB / schema / migrations / queries ────────────────────────────
  *supabase*|*firestore*|*postgres*|*mysql*|*"firebase functions"*|*"base de datos"*|\
  *schema*|*migration*|*query*|*índice*|*index*|*"slow query"*|*explain*|*rls*|\
  *"row-level security"*|*cdc*|*"event sourcing"*|*etl*|*elt*|*dbt*|*"data lake"*|\
  *"data warehouse"*|*pgvector*|*"vector store"*|*embedding*)
    ROUTE="data-engineer" ;;

  # ── Ship-it skill (last — broad keywords like "merge"/"push") ────────────
  *commit*|*"pull request"*|*" pr "*|*merge*|*ship*|*push*)
    ROUTE="ship-it (skill)" ;;
esac

if [ -n "$ROUTE" ]; then
  echo "[LA BESTIA] → Try \`@$ROUTE <your prompt>\` to delegate, or continue directly."
fi
exit 0
