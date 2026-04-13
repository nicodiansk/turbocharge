Source vhs/_common.tape
Output images/scenes/11pm-skip.gif

# BEFORE — tired developer skipping review at 11 PM
Type "# 11:07 PM. Feature works. Ship it?"
Sleep 1s
Enter
Type "git commit -m 'feat: checkout flow' && git push"
Sleep 800ms
Enter
Sleep 1500ms
Type "# (two days later: bug found in review)"
Sleep 1500ms
Enter
Sleep 800ms

# AFTER — turbocharge gates completion on review chain
Type "/turbocharge:build"
Sleep 600ms
Enter
Sleep 1s
Type "# builder -> spec-reviewer -> quality-reviewer"
Sleep 1s
Enter
Type "# task cannot exit until both reviewers pass"
Sleep 1500ms
Enter
Sleep 1s
