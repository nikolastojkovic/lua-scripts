# Contributing to F3L Lua Training Script

Thank you for wanting to contribute! This document explains how to work with this project.

## 📋 Commit Message Format

This project follows **Conventional Commits** for automatic versioning and changelog generation.

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type (Required)
- **feat**: A new feature (bumps minor version: 0.1.0 → 0.2.0)
- **fix**: A bug fix (bumps patch version: 0.1.0 → 0.1.1)
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring without feature changes
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Build process, dependencies, tooling
- **ci**: CI/CD workflow changes
- **revert**: Reverting a previous commit

### Scope (Optional)
Specify what part of the script is affected:
- `timing` - Working/flight time logic
- `voice` - Voice announcements
- `landing` - Landing detection
- `ui` - Display/interface
- `core` - Core logic

### Subject (Required)
- Use imperative mood: "add feature" not "adds feature"
- Don't capitalize first letter
- No period (.) at the end
- Max 50 characters

### Examples

✅ **Good:**
```
feat(timing): add offset tracking for timer accuracy
fix(landing): prevent instant re-launch on elevator hold
docs: update README with installation steps
```

❌ **Bad:**
```
Added feature                    # Missing type
feat: Adds timer offset         # Capitalized, not imperative
fix(landing): prevents instant  # Not lowercase type
feat(landing): improved landing detection.  # Period at end
```

## 🔒 Before Submitting a PR

1. **Check your commits** use conventional format (GitHub will validate)
2. **Lint your code**:
   ```bash
   luacheck f3l.lua --config .luacheckrc
   ```
3. **Test on real hardware** if possible

## 🚀 Breaking Changes

If your change breaks backwards compatibility, add:
```
feat(api): new command format

BREAKING CHANGE: old format no longer supported
```
This will bump the major version (0.1.0 → 1.0.0)

## 📦 Release Process

After your PR is merged to `main`:
1. Workflow automatically validates commit messages ✓
2. Version is auto-bumped based on commit types
3. Release is created on GitHub with changelog
4. Your script is attached as a release asset

## ❓ Questions?

Check the [CHANGELOG.md](CHANGELOG.md) to see version history and changes.
