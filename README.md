
# AI.NVIM

AI chatbot plugin written in vimscript with test driven development.

This repo follows the kernel's style guide but with 4 space indenting instead
of 8.

This plugin uses [copilot.vim](https://github.com/github/copilot.vim) for
authentication so install that. The plugin will not work if you have not
authenticated with copilot and tests will fail.

Currently the only AI provider supported by this plugin is Github Copilot.
Support for other providers is planned but not currently supported with Ollama
being the highest priority out of the unsupported providers. See the
[todos](./TODO.md) for my notes on future features.

# USAGE

To see how to use the plugin look at the [docs](./doc/ai.nvim.txt).

Or run `make` to run the tests and have them explain the plugin:

```
Starting...Scheduling: tests/ai_spec.lua

========================================
Testing: tests/ai_spec.lua
SUCCESS :Ai does not error
SUCCESS :Ai reuses the last chat name
SUCCESS :Ai reuses the last chat window
SUCCESS :Ai puts the cursor at the bottom of the chat
SUCCESS :Ai gets a new token if /chat/completions complains about expired token
SUCCESS :Ai supports streaming
SUCCESS :Ai only writes responses to the last chat on submission
SUCCESS :Ai! does not error
SUCCESS :Ai! creates a new empty chat
SUCCESS :Ai! reuses the last chat window
SUCCESS :Ai! puts the cursor at the bottom of the chat
SUCCESS :Ai[!] [prompt] accepts a prompt as an argument
SUCCESS :Ai[!] [prompt] passes [prompt] to the buffer
SUCCESS :Ai[!] [prompt] gets cached token if token is not expired on submit
SUCCESS :Ai[!] [prompt] gets a new token if token is expired on submit
SUCCESS :Ai[!] [prompt] gets a new token if no token exists on submit
SUCCESS :Ai[!] [prompt] gets a new token if token is malformed on submit
SUCCESS :Ai[!] [prompt] gets new models if token is expired on submit
SUCCESS :Ai[!] [prompt] gets new models if no token exists on submit
SUCCESS :Ai[!] [prompt] gets new models if no models exist on submit
SUCCESS :Ai[!] [prompt] populates the chat with a response
SUCCESS :Ai[!] [prompt] creates ai.nvim dir itself
SUCCESS :Ai <Tab> completes the first argument with models
SUCCESS :Ai g<Tab> completes with models that start with g
SUCCESS :Ai [model] sets the model to [model]
SUCCESS :Ai [model] does not go to a chat
SUCCESS :Ai [model] [prompt] does not pass [model] to the chat
SUCCESS :Ai [model] <Tab> does not complete after first argument
SUCCESS :[range]Ai accepts a range without error
SUCCESS :[range]Ai passes the selected range to the buffer
SUCCESS :[range]Ai [prompt] passes the selected range and [prompt] to the buffer
SUCCESS :[range]Ai wraps ranges in codeblocks if filetype is set
SUCCESS :[range]Ai wraps ranges in codeblocks
SUCCESS :[range]Ai works for single line ranges
SUCCESS :vert Ai accepts a prompt as an argument with a vertical prefix
SUCCESS ai#nvim_get_dir() returns a normal ai.nvim directory
SUCCESS ai#nvim_get_dir() returns the default mock directory under test
SUCCESS ai#nvim_get_dir() returns a specific mock directory under test if specified
SUCCESS providers#get() returns a list of providers
SUCCESS providers#get_models() returns all models for all providers
SUCCESS providers#copilot#submit_chat() debounces chat submission by throwing an error
SUCCESS providers#copilot#get_local_token() successfully gets oauth_token from apps.json
SUCCESS :Ai log opens the log.md
SUCCESS :Ai l opens the log.md
SUCCESS :Ai messages sends the contents of :messages to the chat
SUCCESS :Ai mes sends the contents of :messages to the chat
SUCCESS g:ai_responses for copilot endpoint /copilot_internal/v2/token returns valid json online
SUCCESS g:ai_responses for copilot endpoint /copilot_internal/v2/token returns valid json offline
SUCCESS g:ai_responses for copilot endpoint /models returns valid json online
SUCCESS g:ai_responses for copilot endpoint /models returns valid json offline
SUCCESS vim.g.ai_test_endpoints can be used to mock endpoints
SUCCESS :Ai chats lists all chats in a quickfix list
SUCCESS :Ai grep <pattern> searches through all chats for <pattern>
========================================
SUCCESS 53
FAILED  0
ERRORS  0
========================================
--------------------------------------------------------------------------------
language                       files          blank        comment          code
--------------------------------------------------------------------------------
test code:
 lua                               5            486            582          2395
 json                             14            172              0          1973
 markdown                          4            319              0           739
 bash                              6            136            164           689
application code:
 vimscript                         4            160              3           553
other:
 asciidoc                          2            140              0           313
 dockerfile                       14             36             28           170
 yaml                              4              7              0           133
 make                              5             27              1           116
 bash                              5             11              0           110
 diff                              2             16             31            67
 text                              1              9              0            33
--------------------------------------------------------------------------------
 sum:                             66           1519            809          7291
--------------------------------------------------------------------------------
```

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

## CLOC

This plugin was made out of spite against the growing trend of all lua-based
Neovim plugins that reinvent half of the features already present in Neovim
leading to excessive bloat.

The `scripts/print_cloc` script uses the [cloc cli
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
- `"^ghu_[[:alnum:]]\\{36}$"` couldn't figure out how to do this lua
    lua regexes are just weak IMO

### Note

I had to refactor the chat to be async and I did experience the pain associated
with writing async in vimscript. But I am taking it as a right of passage. I
probably won't write my next plugin in vimscript and I might rewrite this in
lua at somepoint. However, this project has made me even better at writing
Neovim lua due to my deeper understanding of the library of tools vimscript
provides to lua.
