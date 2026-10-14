#!/usr/bin/env bash
# ABOUTME: Asserts workflows/review-swarm.js has a literal meta block and the right lens/verify behavior.
# ABOUTME: Content checks use grep/awk; behavior runs the script under node with stubbed agent() (skips without node and jq).
source "$PLUGIN_DIR/scripts/tests/helpers.sh"
W="$PLUGIN_DIR/workflows/review-swarm.js"
assert_file "$W" || exit 1

# --- content ---
[ "$(awk 'NR==1 { sub(/\r$/, ""); print; exit }' "$W")" = "export const meta = {" ] \
    || { echo "    line 1 of review-swarm.js must be 'export const meta = {'"; exit 1; }
META=$(awk '{ sub(/\r$/, "") } { print } $0 == "}" { exit }' "$W")
if printf '%s\n' "$META" | grep -qE '`|\$\{|\(|\.\.\.'; then
    echo "    the meta block must be a pure literal (no backtick, \${, ( or ...)"; exit 1
fi
for p in "name: 'review-swarm'" "'Find'" "'Verify'" "CAP = 25" "CRITICAL_VOTES = 3" \
         "agentType: 'turbocharge:code-reviewer'" "model: 'sonnet'" "Review Focus" \
         "plan-compliance" "correctness" "test-gaps" "security" "silent-failures"; do
    assert_grep "$W" "$p" || exit 1
done
for p in 'Date\.now' 'Math\.random' 'new Date()' '^import ' '[^a-zA-Z]import('; do
    assert_no_grep "$W" "$p" || exit 1
done

# --- behavior ---
if ! command -v node >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "    node or jq not installed, skipping behavioral checks"
    exit 0
fi
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/tc-swarm.XXXXXX")
trap 'rm -rf "$SCRATCH"' EXIT
cat > "$SCRATCH/harness.js" <<'JS'
// Runs the workflow body as the runtime would: AsyncFunction(agent, parallel, pipeline, phase, log, args, budget).
const fs = require('fs')
const [, , wf, scenario] = process.argv
const S = JSON.parse(scenario)
const src = fs.readFileSync(wf, 'utf8').replace(/\r/g, '').replace(/^export const meta/m, 'const meta')
const calls = [], logs = []
const has = (o, k) => Object.prototype.hasOwnProperty.call(o, k)
const agent = async (prompt, opts = {}) => {
  calls.push({ label: opts.label, opts })
  const answers = S.answers || {}
  if (has(answers, opts.label)) return answers[opts.label]
  if (String(opts.label).indexOf('verify ') === 0) return has(S, 'defaultVerify') ? S.defaultVerify : { verdict: 'confirmed', evidence: 'e', reason: 'r' }
  return { findings: [], declined: [] }
}
const parallel = (thunks) => Promise.all(thunks.map((t) => Promise.resolve().then(t).catch(() => null)))
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor
const fn = new AsyncFunction('agent', 'parallel', 'pipeline', 'phase', 'log', 'args', 'budget', src)
fn(agent, parallel, null, () => {}, (m) => logs.push(String(m)), S.args, {})
  .then((result) => console.log(JSON.stringify({ result, calls, logs })))
  .catch((e) => { console.error(e && e.stack || e); process.exit(2) })
JS
# run NAME SCENARIO_JSON — writes $SCRATCH/NAME.json
run() { node "$SCRATCH/harness.js" "$W" "$2" > "$SCRATCH/$1.json" || { echo "    harness failed for $1"; exit 1; }; }
# check NAME JQ_EXPR — assert a jq expression on a run's output
check() { jq -e "$2" "$SCRATCH/$1.json" >/dev/null || { echo "    [$1] jq check failed: $2"; exit 1; }; }

ARGS='{"base":"b1","head":"h1","files":["a.py","b.py"],"plan":"","context":[],"stat":""}'
run clean "{\"args\":$ARGS}"
check clean '.calls | length == 5'
check clean '[.calls[].label] | sort == ["correctness","plan-compliance","security","silent-failures","test-gaps"]'
check clean '.calls[] | select(.label=="plan-compliance") | .opts.agentType == "turbocharge:code-reviewer" and (.opts | has("model") | not)'
check clean '[.calls[] | select(.label!="plan-compliance") | .opts.model] | all(. == "sonnet")'
check clean '[.calls[].opts.schema.required | sort] | all(. == ["declined","findings"])'
check clean '[.calls[].opts.phase] | all(. == "Find")'
check clean '.result.verdict == "Yes"'

run empty '{"args":{"base":"b1","head":"h1","files":[]}}'
check empty '.calls | length == 0'
check empty '.result.verdict == "Yes"'

run nosec "{\"args\":$ARGS,\"answers\":{\"security\":null}}"
check nosec '.result.verdict == "Incomplete"'
check nosec '.result.dropped | map(select(contains("security"))) | length == 1'
exit 0
