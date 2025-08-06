# Contributing to Lido Community Staking Module

Welcome to the Lido Community Staking Module project! We appreciate your interest in contributing.

## Development Setup

For initial setup, see the [Getting Started](README.md#getting-started) section in the README.

Additional setup for development:

```bash
just deps-dev
```

## Development Workflow

1. **Branch**: Create a feature branch

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Develop**: Make your changes

3. **Test**: Ensure all tests pass (see [Run tests](README.md#run-tests) section for details)

   ```bash
   just test-unit
   just test-local
   ```

4. **Commit**: Follow conventional commits

   ```text
   **Examples:**
   feat: add validator key rotation
   fix: resolve bond calculation overflow
   ```

5. **PR**: Create a pull request using the template
