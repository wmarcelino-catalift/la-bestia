#!/usr/bin/env bash
# UserPromptSubmit hook
# Suggests which subagent to use based on prompt keywords.
# Outputs hint to stdout — Claude treats it as additional context, not as a directive.

set -u

PROMPT="${CLAUDE_USER_PROMPT:-}"
[ -z "$PROMPT" ] && exit 0

# Lowercase for matching
P=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

ROUTE=""

case "$P" in
  *arquitectura*|*diseño*|*tradeoff*|*"vs "*|*patrón*|*escalabilidad*|*adr*)
    ROUTE="architect" ;;
  *auth*|*login*|*password*|*payment*|*pago*|*secret*|*token*|*owasp*|*permission*|*csrf*|*xss*|*sql\ injection*)
    ROUTE="security-auditor" ;;
  *bug*|*"no funciona"*|*rompe*|*crash*|*fail*|*error*|*broken*|*stack\ trace*)
    ROUTE="debugger" ;;
  *idea*|*feature\ nuevo*|*producto*|*negocio*|*estrategia*|*roadmap*|*priorizar*|*build\ vs\ buy*|*comprar\ vs\ construir*)
    ROUTE="cto-strategist" ;;
  *implementar*|*"crear feature"*|*tdd*|*test*|*coverage*)
    ROUTE="test-engineer" ;;
  *review*|*"check this"*|*revisá*|*revisa*)
    ROUTE="code-reviewer" ;;
  *commit*|*"pull request"*|*" pr "*|*merge*|*ship*|*deploy*|*push*)
    ROUTE="ship-it (skill)" ;;
esac

if [ -n "$ROUTE" ]; then
  echo "[ROUTING HINT] Considera delegar a: $ROUTE"
fi

exit 0
