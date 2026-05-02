#!/usr/bin/env bash
# UserPromptSubmit hook — suggest a subagent based on prompt keywords.

set -u

PROMPT="${CLAUDE_USER_PROMPT:-}"
[ -z "$PROMPT" ] && exit 0

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
  *commit*|*"pull request"*|*" pr "*|*merge*|*ship*|*push*)
    ROUTE="ship-it (skill)" ;;
  *eas*|*"expo build"*|*"firebase deploy"*|*emulador*|*emulator*|*"github actions"*|*" ci "*|*pipeline*|*"eas build"*|*"eas submit"*|*"eas update"*|*hosting*|*"cloud functions"*|*deploy*|*build*)
    ROUTE="devops" ;;
  *supabase*|*firestore*|*"firebase functions"*|*"base de datos"*|*schema*|*migration*|*query*|*índice*)
    ROUTE="architect (data layer)" ;;
esac

[ -n "$ROUTE" ] && echo "[ROUTING HINT] Considera delegar a: $ROUTE"
exit 0
