:Ai chats <chat> selects that chat
:Ai chats lists all chats
:Ai clean deletes all chats
:Ai mrproper deletes ai.nvim dir
:Ai explain changes the system prompt to a more verbose one
:Ai -- <models|chats|...> treats the second argument as the prompt
:Ai log enable enables logging to log.md
:Ai log disable disables logging to log.md
:Ai log obfuscate enable enables logging obfuscation
:Ai log obfuscate disable disables logging obfuscation
:Ai <model> <temperature|top_p|max_tokens|n|system_prompt> prints the value of that model's paramter
:Ai <model> <temperature|top_p|max_tokens|n|system_prompt>=<value> assigns the value to that model's paramter
:Ai!! to resend last message sent to last chat to new chat

# TODO

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

- add functionality to support livestreaming of contents or atleast
  non-blocking maybe

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

- just mock the server by having it serve the types of data that could be
  recieved. this way the entire stack gets tested not just portions
    - now you will be able to mock all the different things each endpoint can
      return
    - ooh and now that can be used to facilitate fuzzing

- lookup table of the system prompt. Like `:Ai explain` could use a system
  prompt that explains how they should explain. or the default system prompt
  could be one that tells it only to respond with codeblocks and if the
  codeblock already has a filetype after ``` then don't specify it in a
  comment

- add logging and a mechanism to save files for collecting test data (watch out
  to disable such instrusive behaviour by default)

- vimscript test suite will print the results so that it can be interpreted as
  :help since the test output is literally the documentation.
- vimscript test suite will work for both vim and neovim

- standardize how you are referencing the chat buffer and bufnr

- a way to repaste what you pasted in an old buffer with :'<,'>Ai to a new
  buffer instead after realising you forgot the !
  :Ai!!

- if what you have selected is already wrapped in a codeblock don't send the
  triple backticks to the chat

- being markdown smart, like if I pass a range of a codeblock of lua code in a
  markdown file, pass lua instead of markdown as the filetype of the codeblock

- if triple backticks appear in the message, escape them

- a way to assert that a test should not hit the network

- need debouncing on submit_chat()

- :Ai log puts you at the bottom of the log

get tokens -> "https://api.github.com/copilot_internal/v2/token"
save as json to providers/copilot/token.json

get models -> "https://api.business.githubcopilot.com/models"
save as json to providers/copilot/models.json

post chat json -> "https://api.business.githubcopilot.com/chat/completions"
will be saved as data/json to providers/copilot/chat.data

so have the docker container reroute api.github.com and
api.business.githubcopilot.com to localhost

So now a test fixture will have

The webserver will mock these end points are return the values

```inputs
copilot_internal/v2/token
models
chat/completions
```

```outputs
providers/copilot/token.json
providers/copilot/models.json
providers/copilot/chat.data
```
