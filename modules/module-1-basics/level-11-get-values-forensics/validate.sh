#!/bin/bash
set -uo pipefail
source "$HM_LIB"

CHART="$SANDBOX/weather-widget"
WANT="$(hm_yaml_get "$CHART/values.yaml" config.apiUrl | jq -r .)"

hm_info "Checking the release values..."
hm_require_deployed weather-widget
ov="$(hm_user_values weather-widget | jq -r '.config.apiUrl // empty')"
[ -z "$ov" ] || hm_fail "The release still carries a user-supplied config.apiUrl override ('$ov')"
hm_ok "No leftover override in the release's user-supplied values"

hm_info "Checking the rendered configuration..."
url="$(hm_jsonpath configmap/weather-widget-config '{.data.config\.json}' | jq -r '.apiUrl // empty')"
[ -n "$url" ] || hm_fail "ConfigMap weather-widget-config has no apiUrl"
[ "$url" = "$WANT" ] || hm_fail "The widget is configured with apiUrl '$url', but the chart's default is '$WANT'"
murl="$(helm get manifest weather-widget -n "$NS" | grep -o '"apiUrl": "[^"]*"' | head -1 | sed 's/.*: "//; s/"$//')"
[ "$murl" = "$WANT" ] || hm_fail "Helm's record of the release still says apiUrl '$murl' - the live ConfigMap was edited behind its back"
hm_ok "apiUrl is $url"

hm_wait_rollout deployment/weather-widget "$NS" 90s
hm_pass "weather-widget talks to the right API again."
