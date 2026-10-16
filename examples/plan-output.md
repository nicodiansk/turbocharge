# Example: Plan Output

This is a sample implementation plan produced by `/turbocharge:plan`.

---

# CLI Worktree Manager Implementation Plan

**Goal:** Build a CLI tool that wraps git worktree with list, create, remove, and clean commands.
**Architecture:** Single Go binary with cobra CLI framework, reads directly from git (no custom state).
**Tech Stack:** Go, cobra, go-git (for status detection)

## Tasks

### Task 1: Project scaffold and list command

**Files:**
- Create: `cmd/root.go`
- Create: `cmd/list.go`
- Create: `cmd/list_test.go`
- Create: `main.go`
- Create: `go.mod`

**Step 1: Write failing test**
```go
func TestListWorktrees_ShowsMainWorktree(t *testing.T) {
    dir := setupTestRepo(t)
    out, err := runCmd(dir, "list")
    require.NoError(t, err)
    assert.Contains(t, out, "main")
}
```

**Step 2: Run test to verify failure**
Run: `go test ./cmd/ -run TestListWorktrees`
Expected: FAIL with "undefined: runCmd"

**Step 3: Implement minimal code**
```go
// cmd/list.go
var listCmd = &cobra.Command{
    Use:   "list",
    Short: "List all worktrees",
    RunE: func(cmd *cobra.Command, args []string) error {
        out, err := exec.Command("git", "worktree", "list", "--porcelain").Output()
        if err != nil {
            return err
        }
        // Parse and format as table
        return printWorktreeTable(out)
    },
}
```

**Step 4: Run test to verify pass**
Run: `go test ./cmd/ -run TestListWorktrees`
Expected: PASS

**Step 5: Commit**
`git commit -m "feat: add list command with table output"`

---

### Task 2: JSON output flag

**Files:**
- Modify: `cmd/list.go`
- Modify: `cmd/list_test.go`

**Step 1: Write failing test**
```go
func TestListWorktrees_JSONOutput(t *testing.T) {
    dir := setupTestRepo(t)
    out, err := runCmd(dir, "list", "--json")
    require.NoError(t, err)
    var result []Worktree
    require.NoError(t, json.Unmarshal([]byte(out), &result))
    assert.Len(t, result, 1)
}
```

**Step 2-5:** [Same TDD cycle pattern]

`git commit -m "feat: add --json flag to list command"`

---

*(Plan continues for Tasks 3-6: create command, remove command, clean command, clean --dry-run)*
