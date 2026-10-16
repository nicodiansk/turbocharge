export const meta = {
  name: 'review-swarm',
  description: 'Verified multi-lens review of a branch diff: five lens reviewers, then verifiers that try to refute each finding',
  whenToUse: 'Launched by /turbocharge:review with the diff scope as args. Not for per-task review.',
  phases: [{ title: 'Find' }, { title: 'Verify' }],
}
// ABOUTME: Review swarm workflow. Five lens reviewers find defects in the branch diff.
// ABOUTME: Findings are deduped, then verifiers try to refute each one, under a 25-agent cap.

const CAP = 25
const CRITICAL_VOTES = 3

const input = typeof args === 'string' ? JSON.parse(args) : (args || {})
const files = input.files || []
const context = input.context || []

const FINDINGS = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'integer' },
          severity: { type: 'string', enum: ['critical', 'important', 'minor'] },
          title: { type: 'string' },
          evidence: { type: 'string' },
        },
        required: ['file', 'line', 'severity', 'title', 'evidence'],
      },
    },
    declined: { type: 'array', items: { type: 'string' } },
  },
  required: ['findings', 'declined'],
}

const SONNET = { model: 'sonnet', effort: 'medium' }

const LENSES = [
  {
    id: 'plan-compliance',
    opts: { agentType: 'turbocharge:code-reviewer' },
    focus: 'Plan alignment: does the diff do what the plan or description asks, nothing missing and nothing extra? If the plan has a Review Focus section, check that every line of it has its pinning test in the task that owns the code; a missing pin is important.',
  },
  {
    id: 'correctness',
    opts: SONNET,
    focus: 'Correctness: logic errors, boundaries (off-by-one, inclusive or exclusive ends), wrong units, wrong types, broken callers of changed code, state that goes stale.',
  },
  {
    id: 'test-gaps',
    opts: SONNET,
    focus: 'Test gaps and inputs nobody specified: the plan\'s Review Focus pins, and what a reasonable user would expect for an empty input, a duplicate, a comma or odd character, a rerun of the same operation. Tests that pass while checking the wrong thing.',
  },
  {
    id: 'security',
    opts: SONNET,
    focus: 'Security: injection, unvalidated input at a boundary, sensitive data written into code or logs, path handling, authorization gaps, unsafe defaults.',
  },
  {
    id: 'silent-failures',
    opts: SONNET,
    focus: 'Silent failures: swallowed errors, fallbacks that hide a problem, exit codes ignored, partial results reported as success, retries that mask a defect.',
  },
]

const PREAMBLE = [
  'You are one lens of a code review. Work read-only: never modify, commit or push.',
  'Diff the range base..head over the listed files. Read each changed file in full, plus the callers of what changed.',
  'Report only defects the diff introduces or exposes, each with file:line at head.',
  'Rate severity by the effect on a reasonable user: critical (wrong results, data loss, security), important (a real gap a user will hit), minor (polish).',
  'Evidence quotes the code. Do not pad: an empty findings list is a valid answer.',
  'Anything that needs a product decision goes in declined: one line with the reason. Do not rule on it.',
  'The plan and context files are named below, not pasted: read them when your lens needs them.',
].join('\n')

function lensPrompt(lens) {
  return [
    PREAMBLE,
    '',
    'Your lens: ' + lens.focus,
    '',
    'base: ' + input.base,
    'head: ' + input.head,
    'files:\n' + files.map((f) => '- ' + f).join('\n'),
    'plan: ' + (input.plan || '(none)'),
    'context files:\n' + (context.length ? context.map((c) => '- ' + c).join('\n') : '(none)'),
    input.stat ? 'diff stat:\n' + input.stat : '',
  ].join('\n')
}

if (files.length === 0) {
  return { verdict: 'Yes', note: 'nothing to review', confirmed: [], refuted: [], unverified: [], declined: [], dropped: [], agents: 0 }
}

const dropped = []
const found = await parallel(
  LENSES.map((lens) => () => {
    return agent(lensPrompt(lens), { label: lens.id, phase: 'Find', schema: FINDINGS, ...lens.opts })
  })
)

const raw = []
const declined = []
found.forEach((res, i) => {
  const id = LENSES[i].id
  if (res === null || res === undefined) {
    log('lens ' + id + ' failed: not covered')
    dropped.push('lens ' + id + ' failed: not covered')
    return
  }
  ;(res.findings || []).forEach((f) => raw.push({ ...f, lenses: [id] }))
  ;(res.declined || []).forEach((d) => declined.push(d))
})

// Barrier: dedupe by file:line, keeping the highest severity.
const RANK = { critical: 0, important: 1, minor: 2 }
const bySpot = new Map()
raw.forEach((f) => {
  const file = String(f.file).replace(/^\.\//, '')
  const spot = file + ':' + f.line
  const prior = bySpot.get(spot)
  if (!prior) {
    bySpot.set(spot, { ...f, file: file, lenses: [...f.lenses] })
    return
  }
  if (RANK[f.severity] < RANK[prior.severity]) prior.severity = f.severity
  f.lenses.forEach((l) => { if (!prior.lenses.includes(l)) prior.lenses.push(l) })
})
const merged = [...bySpot.values()].sort(
  (a, b) => RANK[a.severity] - RANK[b.severity] || a.file.localeCompare(b.file) || a.line - b.line
)
const uniqueDeclined = [...new Set(declined)]

// Cap: verifier slots are what is left of CAP after the lens calls. A finding that does not fit
// is reported as unverified, never dropped.
const votesFor = (f) => (f.severity === 'critical' ? CRITICAL_VOTES : 1)
let slots = CAP - LENSES.length
const toVerify = []
const unverified = []
merged.forEach((f) => {
  const cost = votesFor(f)
  if (cost <= slots) {
    slots -= cost
    toVerify.push(f)
  } else {
    log('agent cap (' + CAP + ') reached: ' + f.file + ':' + f.line + ' not verified')
    unverified.push({ ...f, why: 'agent cap (' + CAP + ')' })
  }
})

const VERDICT = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['confirmed', 'refuted', 'uncertain'] },
    evidence: { type: 'string' },
    reason: { type: 'string' },
  },
  required: ['verdict', 'evidence', 'reason'],
}

function verifyPrompt(f) {
  return [
    'Try to refute this review finding against the code at head. Read-only.',
    'base: ' + input.base,
    'head: ' + input.head,
    'plan: ' + (input.plan || '(none)'),
    'Finding (' + f.severity + ') at ' + f.file + ':' + f.line + ': ' + f.title,
    'Evidence given: ' + f.evidence,
    'Return confirmed only if the code shows the defect, refuted if the code shows the claim is wrong, uncertain otherwise.',
  ].join('\n')
}

const tally = await parallel(
  toVerify.map((f) => async () => {
    const n = votesFor(f)
    const votes = await parallel(
      Array.from({ length: n }, (_, k) => () =>
        agent(verifyPrompt(f), {
          label: 'verify ' + f.file + ':' + f.line + ' #' + (k + 1),
          phase: 'Verify',
          agentType: 'turbocharge:verifier',
          schema: VERDICT,
        })
      )
    )
    return { f: f, votes: votes }
  })
)

const confirmed = []
const refuted = []
tally.forEach((t) => {
  if (t === null) return
  const need = Math.floor(t.votes.length / 2) + 1
  const yes = t.votes.filter((v) => v && v.verdict === 'confirmed')
  const failed = t.votes.filter((v) => v === null || v === undefined).length
  if (yes.length >= need) {
    confirmed.push({ ...t.f, verification: yes[0].evidence })
  } else if (yes.length + failed >= need) {
    unverified.push({ ...t.f, why: 'verifier failed' })
  } else {
    const no = t.votes.find((v) => v && v.verdict !== 'confirmed')
    const reason = no.verdict === 'uncertain' ? 'uncertain: ' + no.reason : no.reason
    refuted.push({ ...t.f, reason: reason })
  }
})

const hasSeverity = (list, sev) => list.some((f) => f.severity === sev)
const open = hasSeverity(unverified, 'critical') || hasSeverity(unverified, 'important')
let verdict = 'Yes'
if (hasSeverity(confirmed, 'critical')) verdict = 'No'
else if (hasSeverity(confirmed, 'important')) verdict = 'With fixes'
else if (dropped.length || open) verdict = 'Incomplete'

return {
  verdict: verdict,
  confirmed: confirmed,
  refuted: refuted,
  unverified: unverified,
  declined: uniqueDeclined,
  dropped: dropped,
  agents: LENSES.length + (CAP - LENSES.length - slots),
}
