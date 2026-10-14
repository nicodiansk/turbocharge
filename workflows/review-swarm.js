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
    focus: 'Security: injection, unvalidated input at a boundary, secrets in code or logs, path handling, authorization gaps, unsafe defaults.',
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

return {
  verdict: dropped.length ? 'Incomplete' : 'Yes',
  findings: raw,
  declined: declined,
  dropped: dropped,
  agents: LENSES.length,
}
