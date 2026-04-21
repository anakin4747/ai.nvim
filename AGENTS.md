# AGENTS.md

## Git Best Practices

- **Commit Often:** Make small, focused commits.
- **Descriptive Messages:** Use clear, imperative commit messages.
- **Test Driven Development:**
  - Write tests before implementing features or fixes.
  - After creating the test, stop and request approval before proceeding.
- **.gitignore:** Exclude build artifacts and sensitive files.
- **No Secrets:** Never commit passwords or API keys.
- **Whitespace:** Never leave trailing whitespace

## Test Suite

This application has a test suite that gets run with the default make target:

```sh
make
```

All tests are in tests/ai_spec.lua.

You will first only add to this file to make the test and then make after I
approve the test you will implement the fix. the test and the fix should be in
separate commits

## Start

Start doing the features listed in TODO.md starting at line 10. Do not modify
TODO.md. I will modify it.

