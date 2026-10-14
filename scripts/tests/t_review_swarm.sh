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
# F LENS FILE LINE SEVERITY — one lens answer holding one finding
F() { printf '{"findings":[{"file":"%s","line":%s,"severity":"%s","title":"t-%s","evidence":"ev-%s"}],"declined":[]}' "$2" "$3" "$4" "$1" "$1"; }
V() { printf '{"verdict":"%s","evidence":"e","reason":"%s"}' "$1" "$2"; }

# dedupe: one finding at a.py:10 from two lenses, highest severity, three critical votes
run dedupe "{\"args\":$ARGS,\"answers\":{\"correctness\":$(F correctness ./a.py 10 important),\"security\":$(F security a.py 10 critical)}}"
check dedupe '.result.confirmed | length == 1'
check dedupe '.result.confirmed[0] | .severity == "critical" and (.lenses | sort == ["correctness","security"]) and .title == "t-correctness"'
check dedupe '[.calls[] | select(.opts.phase == "Verify") | .label] | sort == ["verify a.py:10 #1","verify a.py:10 #2","verify a.py:10 #3"]'
check dedupe '[.calls[] | select(.opts.phase == "Verify") | .opts.agentType] | all(. == "turbocharge:verifier")'
check dedupe '.result.verdict == "No"'

# majority: confirmed/confirmed/refuted -> confirmed; confirmed/refuted/uncertain -> refuted
A="\"answers\":{\"security\":$(F security a.py 10 critical)"
run maj1 "{\"args\":$ARGS,$A,\"verify a.py:10 #1\":$(V confirmed x),\"verify a.py:10 #2\":$(V confirmed x),\"verify a.py:10 #3\":$(V refuted guarded)}}"
check maj1 '(.result.confirmed | length) == 1 and (.result.refuted | length) == 0'
run maj2 "{\"args\":$ARGS,$A,\"verify a.py:10 #1\":$(V confirmed x),\"verify a.py:10 #2\":$(V refuted guarded),\"verify a.py:10 #3\":$(V uncertain unsure)}}"
check maj2 '(.result.confirmed | length) == 0 and (.result.refuted | length) == 1'
check maj2 '.result.refuted[0].reason == "guarded"'

# a null verifier is not verified: never confirmed, never refuted
run null1 "{\"args\":$ARGS,\"answers\":{\"correctness\":$(F correctness a.py 10 important),\"verify a.py:10 #1\":null}}"
check null1 '(.result.unverified | length) == 1 and .result.unverified[0].why == "verifier failed"'
check null1 '(.result.confirmed | length) == 0 and (.result.refuted | length) == 0'
check null1 '.result.verdict == "Incomplete"'
run null3 "{\"args\":$ARGS,$A,\"verify a.py:10 #1\":$(V confirmed x),\"verify a.py:10 #2\":null,\"verify a.py:10 #3\":$(V refuted guarded)}}"
check null3 '(.result.unverified | length) == 1 and (.result.confirmed | length) == 0 and (.result.refuted | length) == 0'

# uncertain counts as refuted
run unsure "{\"args\":$ARGS,\"answers\":{\"correctness\":$(F correctness a.py 10 important),\"verify a.py:10 #1\":$(V uncertain cannot-tell)}}"
check unsure '(.result.refuted | length) == 1 and (.result.refuted[0].reason | startswith("uncertain"))'
check unsure '.result.verdict == "Yes"'

# cap: 30 distinct important findings -> 20 verifier calls, 25 agents, 10 capped and logged
MANY=$(jq -nc '{findings: [range(1;31) | {file: "f.py", line: ., severity: "important", title: "t", evidence: "e"}], declined: []}')
run cap "{\"args\":$ARGS,\"answers\":{\"correctness\":$MANY}}"
check cap '[.calls[] | select(.opts.phase == "Verify")] | length == 20'
check cap '.result.agents == 25'
check cap '[.result.unverified[] | select(.why == "agent cap (25)")] | length == 10'
check cap '[.logs[] | select(contains("agent cap"))] | length >= 1'

# verdicts
run vimp "{\"args\":$ARGS,\"answers\":{\"correctness\":$(F correctness a.py 10 important)}}"
check vimp '.result.verdict == "With fixes"'
run vmin "{\"args\":$ARGS,\"answers\":{\"correctness\":$(F correctness a.py 10 minor)}}"
check vmin '.result.verdict == "Yes" and (.result.confirmed | length) == 1'

# the same declined line from two lenses appears once
D='{"findings":[],"declined":["error text wording: product call"]}'
run decl "{\"args\":$ARGS,\"answers\":{\"correctness\":$D,\"security\":$D}}"
check decl '.result.declined == ["error text wording: product call"]'
exit 0
