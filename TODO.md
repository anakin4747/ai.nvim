
# TODO

:Ai chats <chat> selects that chat
:Ai chats lists all chats
:Ai chats <tab> allows you to select old conversations
:Ai clean <chat> deletes that chat
:Ai cleanall deletes all chats
:Ai mrproper deletes ai.nvim dir
:Ai explain changes the system prompt to a more verbose one
:Ai -- <models|chats|...> treats the second argument as the prompt
:Ai log enable enables logging to log.md
:Ai log disable disables logging to log.md
:Ai log obfuscate enable enables logging obfuscation
:Ai log obfuscate disable disables logging obfuscation
:Ai <model> <temperature|top_p|max_tokens|n|system_prompt> prints the value of that model's paramter
:Ai <model> <temperature|top_p|max_tokens|n|system_prompt>=<value> assigns the value to that model's paramter
:Ai!! to resend last message sent to last chat to new chat or just the case when you use ! wrong either used it when you didn't mean to or vica versa
:Ai prompt opens the file that is used for the user prompt
:Ai prompt user opens the file that is used for the user prompt
:Ai prompt system opens the file that is used for the system prompt
:%Ai edit edits the changes to the file directly
:Ai diagnostics sends vim.diagnostic.get() to ai buffer and also wraps it in fold markers and close only that fold to lightly hide it from the user
:Ai grep to :grep through your chats
:%Ai automatically provides watching of % so that we don't need to explicitly ask Ai to watch it and so that we don't need to keep sending it the same file with minor changes
:%Ai also inserts a commented out name of the file at the top
:%Ai for files larger than like 20 lines gets automatically folded so that they are easier to move around
:Ai <filename> would be the way to pass a file different from % to the chat as well as enable watching automatically for that file
:Ai do changes the system prompt or using ACP stuff to do agentic stuff like actualing going and editing files itself

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

- improve tab completion for :Ai <tab> since it doesn't complete if you already
  begin typing an option like :Ai g<tab> does not complete anything

- lookup table of the system prompt. Like `:Ai explain` could use a system
  prompt that explains how they should explain. or the default system prompt
  could be one that tells it only to respond with codeblocks and if the
  codeblock already has a filetype after ``` then don't specify it in a
  comment

- vimscript test suite will print the results so that it can be interpreted as
  :help since the test output is literally the documentation.
- vimscript test suite will work for both vim and neovim

- standardize how you are referencing the chat buffer and bufnr

- if what you have selected is already wrapped in a codeblock don't send the
  triple backticks to the chat

- being markdown smart, like if I pass a range of a codeblock of lua code in a
  markdown file, pass lua instead of markdown as the filetype of the codeblock
  use :Inspect to figure this out easier

- if triple backticks appear in the message, escape them

- need debouncing on submit_chat()

- :Ai log puts you at the bottom of the log

---

all of the sub commands are stored in a structure to support sub sub commands
and sub sub sub commands to ensure they are all able to be abbreviated and so
that they can all be automatically filled out for the tab completion

---

Hitting enter while over a line in a codeblock runs it in the closests open
terminal. If one is not open, open one to run it in.
If you hit enter on the top of the codeblock (ie the ```<filetype>) the entire
code block is ran.

---

Asynchronous chat submissions

Buffer updates with a loading animation of sorts (what kind? TBD)

MCP and ACP support

everytime a command is run in a shell with ai.nvim it opens a terminal buffer
and runs the command. This could be in the background or take up a window. but
this is the best way I want to interact with agents running long running
commands so that I can view it. I also want a way to view more of the
communication with tools and MCP stuff.

---

:Ai agent enable
    enables agent mode opposed to the default chat mode that is fairly limited
    since it does not have agentic capabilities
:Ai agent disable
    switches back to the default chat mode

---

Having the hit enter at codeblocks would be so sweet rn

running the commands in :terminals so that they can always be watched and
interacted with directly

---

support for highlighting commands from the :Ai buffer to run those in a
:terminal buffer


---

tell ai to always use

```
sudo chown $(id -nu):$(id -ng) /srv/samba/share
```

instead of

```
sudo chown <youruser>:<youruser> /srv/samba/share
```

So that it is always runnable code

---

Or when requiring edits to a file don't do this:

```bash
# 5. Edit Samba config
sudo nano /etc/samba/smb.conf

# Add at the end:
# [Share]
#    path = /srv/samba/share
#    browseable = yes
#    read only = no
#    guest ok = no
#    valid users = <youruser>
```

Do this instead:

```bash
sudo cat >> /etc/samba/smb.conf << EOF
[Share]
   path = /srv/samba/share
   browseable = yes
   read only = no
   guest ok = no
   valid users = $(id -nu)
EOF
```

---

Use sed or cat to perform file edits so that they can be more easily seen as
they will be on display in the :terminal buffers. That is compared to using an
mcp or some Ai tool for reading or writing, which is just harder to introspect
into, why not keep it simple and just use sed and cat so that we can monitor it
the way we always can.

---

ask AI to make grammarly but open source and as a language server

---

Properly handle the case of no internet connection

---

do a little :<line1>,<line2>normal == to left align indent text in the range
you just passed

---

make chat buffers unlisted

---

file diffs for applying changes
while hovering over a diff <cr> to accept diff and <C-c> to decline diff. Maybe
<cr><cr> and <C-c><C-c> idk

---

big files getting insert in fold markers and folded automatically

---

handle the error condition properly when the chat is too large

---

when files are being watched have that listed at the top of the AI's response
so that we can see what files were watched during that response

---

# to support async sending

Currently the application blocks on sending chat data

On sending chat data

Worst case:
    - curl token
    - curl models
    - curl chat data

best case:
    - token exists
    - models exists
    - curl chat data
