
AI chatbot tool written in vimscript with test driven development

This repo follows the kernel's style guide but with 4 space indenting instead
of 8

# How it works

First a GET request at /copilot_internal/v2/token:

Then we get json in return

So to test you should write the json out to a file so that it can be easily
switched out


writing to the chat buffer is how you will send. this allows you to decouple
the ai adapter by making the ai adapter act on autocmds when the request get
written to the buffer. So the UI main has to focus on getting the text from the
user into the buffer and the LLM just needs to read the chat from the file.

add tests for other modifiers like botright, topleft, etc

I was not able to catch this error with a test:
```
Error detected while processing function ai#main[17]..<SNR>61_open_chat:
line    6:
E37: No write since last change (add ! to override)
```

I have resolved it with a `slient!` before `edit`

bug for a range with a single line not working

So you will need to have a locking mechanism so that you do not edit the
buffer will its doing its handshake, or you can have a way so that it will
always just append the most recent file.

Soon you will need to investigate how to dynamically generate tests to account
for every comination of every feature

    bang vs no bang
    range vs modifiers vs no prefix
    prompt vs no prompt
    model vs no model

