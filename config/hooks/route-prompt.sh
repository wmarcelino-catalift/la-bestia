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
  *bug*|*"no funciona"*|*rompe*|*crash*|*fail*|*error*|*broken*|*stack\ trace*|*"no carga"*|*"no aparece"*|*"no se ve"*)
    ROUTE="debugger" ;;
  *verifica*|*chequea*|*"revisa esto"*|*arregla*|*repara*|*"fix this"*|*"qué pasa"*)
    ROUTE="debugger" ;;
  *idea*|*feature\ nuevo*|*producto*|*negocio*|*estrategia*|*roadmap*|*priorizar*|*build\ vs\ buy*|*comprar\ vs\ construir*|*"lista de tareas"*|*"todo list"*|*pendientes*)
    ROUTE="cto-strategist (Plan Mode primero para >5 tareas)" ;;
  *implementar*|*"crear feature"*|*tdd*|*test*|*coverage*|*"agrega "*|*"add "*|*"crea un"*)
    ROUTE="test-engineer" ;;
  *review*|*"check this"*|*revisá*|*"revisa el código"*|*"revisa este"*)
    ROUTE="code-reviewer" ;;
  *"rn "*|*"react native"*|*flatlist*|*stylesheet*|*"memory leak"*|*"re-render"*|*"pantalla "*|*"componente "*)
    ROUTE="mobile-reviewer" ;;
  *"ux "*|*"diseño de "*|*"modal "* |*"pantalla de "*|*brand*|*"se ve mal"*|*"loading state"*|*"empty state"*)
    ROUTE="ux-reviewer" ;;
  *"meal plan"*|*receta*|*ingrediente*|*"foto de"*|*"imagen de"*|*"actualiza el contenido"*|*"actualiza firestore"*)
    ROUTE="content-manager" ;;
  *commit*|*"pull request"*|*" pr "*|*merge*|*ship*|*push*)
    ROUTE="ship-it (skill)" ;;
  *eas*|*"expo build"*|*"firebase deploy"*|*emulador*|*emulator*|*"github actions"*|*" ci "*|*pipeline*|*"eas build"*|*"eas submit"*|*"eas update"*|*hosting*|*"cloud functions"*|*deploy*|*build*)
    ROUTE="devops" ;;
  *supabase*|*firestore*|*"firebase functions"*|*"base de datos"*|*schema*|*migration*|*query*|*índice*)
    ROUTE="architect (data layer)" ;;
esac

if [ -n "$ROUTE" ]; then
  echo "[LA BESTIA] → Escribí \`@$ROUTE <tu pregunta>\` para delegarlo, o seguí directo."
fi
exit 0
