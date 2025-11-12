
AI chatbot tool written in vimscript with test driven development

This repo follows the kernel's style guide but with 4 space indenting instead
of 8

# TODO

- buffer locking? maybe

- Soon you will need to investigate how to dynamically generate tests to
  account for every comination of every feature
  ```
  bang vs no bang
  range vs modifiers vs no prefix
  prompt vs no prompt
  model vs no model
  ```
- standardize on all the files that are being interacted with so that all the
  tests can mock them individually in their own little sandbox, also so that
  files that get created by the tests can be cleaned up
  ```
  apps.json = "$HOME/.config/github-copilot/apps.json"
  token.json = $"{ai#get_cache_dir()}/providers/copilot/token.json"
  ```
- you could say which files are inputs/outputs will be generated etc
  what would be the easiest most straight forward way to have a global list of
  all the files a test could interact with so that they can all be mocked

- standardize on the ai.nvim dir you want to have. Does it need to be
  stdpath("cache")? maybe replace it with "state" so that the naming makes more
  sense.

- the fixtures also need to be standardized

- standardize variable naming based on type maybe

- need to add test for VISUAL mode compatibility not just VISUAL_LINE mode

- tracing and logging

