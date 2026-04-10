## No CLAUDE.md Detected

This project has no `CLAUDE.md`. Suggest the user run `/init` to generate one.

After `/init`, suggest adding these turbocharge-compatible sections:

### Domain Terms
A table mapping project-specific vocabulary so all skills share a common language:
```
| Term | Definition |
|------|------------|
| Widget | A configurable UI component in the dashboard |
| Ingestion | The pipeline that imports raw data from external sources |
```

### ABOUTME Convention
Every file should start with a 2-line comment describing what it does:
```
# ABOUTME: Handles user authentication and session management.
# ABOUTME: Wraps OAuth2 flow with refresh token rotation.
```

### TDD Workflow
A section describing the project's test-first expectations so `/turbocharge:build` can enforce them.

### Debugging Protocol
A section describing systematic debugging steps so `/turbocharge:debug` can follow them.

### Naming Conventions
Rules for naming files, functions, and variables — avoids style arguments during build and review.
