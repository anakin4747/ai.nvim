
# AI.NVIM

AI chatbot plugin written in vimscript with test driven development.

This repo follows the kernel's style guide but with 4 space indenting instead
of 8.

## TDD

This project uses Plenary Busted for its test suite and
[`cqfd`](https://github.com/savoirfairelinux/cqfd) for reproducible setups
inside docker.

To run the tests with cqfd:

```sh
make
```

To run the tests without cqfd:

```sh
make test
```

Currently the tests look something like this:

```
Starting...Scheduling: tests/ai_spec.lua

========================================
Testing:        /home/kin/src/nvim.cfg/pack/ai.nvim/start/ai.nvim/tests/ai_spec.lua
Success ||      :Ai does not error
Success ||      :Ai reuses the last chat name
Success ||      :Ai reuses the last chat window
Success ||      :Ai puts the cursor at the bottom of the chat
Success ||      :Ai! does not error
Success ||      :Ai! creates a new empty chat
Success ||      :Ai! reuses the last chat window
Success ||      :Ai! puts the cursor at the bottom of the chat
Success ||      :Ai <prompt> accepts a prompt as an argument
Success ||      :Ai <prompt> passes <prompt> to the buffer
...
Success:        28
Failed :        0
Errors :        0
========================================
--------------------------------------------------------------------------------
language                       files          blank        comment          code
--------------------------------------------------------------------------------
test code:
 json                              2              0              0           768
 lua                               2            101             38           276
application code:
 vimscript                         4             51              5           169
other:
 markdown                          1             19              0            45
 make                              1              2              0            21
 dockerfile                        1              2              0            10
--------------------------------------------------------------------------------
 sum:                             12            176             43          1294
--------------------------------------------------------------------------------
```

## DOCS

The tests document themselves so the tests and the test output are the
documentation. Hopefully, I will find time to generate actual vimdocs.

## CLOC

This plugin was made out of spite against the growing trend of all lua-based
Neovim plugins that reinvent half of the features already present in Neovim
leading to excessive bloat.

The `cloc` Makefile target uses the [cloc cli
tool](https://github.com/AlDanial/cloc) to Count Lines Of Code to emphasize
that this plugin is lean. TDD also inherently promotes a lean codebase.

## VIMSCRIPT

This plugin is written in vimscript and tested in lua.

Vimscript teaches you more about vim than lua does. Vimscript also has the
best developer experience a language could offer due to the immediate in-editor
documentation for the entire language. Which doesn't work as well with lua.

I love Lua but some of the following reasons are why I dislike lua:
- `error()` truncates filepaths
- 0 is truthy
- 1 based indexing
- 2 space indenting is the norm
- `vim.fn.readfile()` in lua != `readfile()` in vimscript

# TODO

- buffer locking? maybe

- Soon you will need to investigate how to dynamically generate tests to
  account for every combination of every feature
  ```
  bang vs no bang
  range vs modifiers vs no prefix
  prompt vs no prompt
  model vs no model
  ```
- standardize variable naming based on type maybe

- need to add test for VISUAL mode compatibility not just VISUAL_LINE mode

- tracing and logging

- do more fuzzing of function arguments and add more error handling when
  everything is more settled down and features are more firm

- three tabs max of indentation in vimscript

- add a test that gets a token if a chat submission returns an error saying
  that the token is expired
  ```
  unauthorized: token expired
  ```

- make it so that the ai always wraps text outside of code blocks boxes at
  &textwidth

- figure out a way for the user to select all of the parameters of the
  conversation currently hardcoded in the post command

- add functionality to support livestreaming of contents or atleast
  non-blocking

- add `:Ai clean` to delete all chats
- add `:Ai mrproper` to delete ai.nvim dir

- add a test to ensure the cursor gets moved to the bottom of the chat after
  getting chat response

- maybe support `:Ai explain` to change the system prompt to asking for an
  explanation instead of only for codeblocks like it is hardcoded to now

- maybe support in file editing??? idk maybe not

- image support in the future

- investigate ACP

- have a way to easily generate test fixtures from the data you send and
  recieve to the chatbot

- improve tab completion for :Ai <tab> since it doesn't complete if you already
  begin typing an option like :Ai g<tab> does not complete anything
