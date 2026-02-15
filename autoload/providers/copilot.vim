
function! providers#copilot#submit_chat() abort
    if g:ai_job_running
        return
    endi

    if s:token_needed()
        call providers#copilot#enqueue_token_fetch()
        call ai#run_job_queue()
        call ai#wait_for_jobs()
    endi

    if s:models_needed()
        call providers#copilot#enqueue_token_fetch()
        call ai#run_job_queue()
        call ai#wait_for_jobs()
        call providers#copilot#enqueue_models_fetch()
    endi

    call providers#copilot#enqueue_chat_submission()

    call ai#run_job_queue()
endf

function! providers#copilot#enqueue_token_fetch() abort
    call ai#enqueue_job(#{
        \ cmd: s:build_token_curl_cmd(),
        \ on_stdout: function('s:handle_token_response'),
        \ stdout_buffered: v:true,
        \ })
endf

function! s:token_needed(localtime = g:ai_localtime) abort
    let copilot_path = $"{ai#nvim_get_dir()}/providers/copilot/"
    let token_json_path = $"{copilot_path}/token.json"

    if !isdirectory(copilot_path) || !filereadable(token_json_path)
        return v:true
    endi

    let token = {}

    try
        let token = json_decode(readfile(token_json_path))
    catch
        return v:true
    endt

    if !exists("token.expires_at")
        return v:true
    endi

    if token.expires_at < a:localtime
        return v:true
    endi

    return v:false
endf

function! s:models_needed()
    let copilot_path = $"{ai#nvim_get_dir()}/providers/copilot/"
    let models_json_path = $"{copilot_path}/models.json"

    if !isdirectory(copilot_path) || !filereadable(models_json_path)
        return v:true
    endi

    try
        call json_decode(readfile(models_json_path))
    catch
        return v:true
    endt

    return v:false
endf

function! providers#copilot#get_local_token() abort
    let apps_json_path = $"{expand("$HOME")}/.config/github-copilot/apps.json"
    let apps_json = apps_json_path->readfile()->join("\n")->json_decode()
    return apps_json[keys(apps_json)[0]]['oauth_token']
endf

function! s:build_token_curl_cmd() abort
    let url = "https://api.github.com/copilot_internal/v2/token"

    let headers = [
        \   $"authorization: Bearer {providers#copilot#get_local_token()}",
        \   $"accept: application/json",
        \]

    return ai#build_curl_cmd(url, "GET", headers)
endf

function! s:handle_token_response(_, response, __) abort
    let g:ai_responses += a:response

    let copilot_dir = $"{ai#nvim_get_dir()}/providers/copilot"

    if !filereadable(copilot_dir)
        call mkdir(copilot_dir, "p")
    endi

    let token_json_path = $"{copilot_dir}/token.json"

    return a:response->writefile(token_json_path)
endf

function! s:get_token() abort
    return $"{ai#nvim_get_dir()}/providers/copilot/token.json"
        \ ->readfile()
        \ ->join("\n")
        \ ->json_decode()
        \ ->get("token")
endf

function! providers#copilot#enqueue_models_fetch()
    call ai#enqueue_job(#{
        \ cmd: s:build_models_curl_cmd(),
        \ on_stdout: function('s:handle_models_response'),
        \ stdout_buffered: v:true,
        \ })
endf

function! s:build_models_curl_cmd() abort
    let url = "https://api.githubcopilot.com/models"
    let token = s:get_token()

    let headers = [
        \   $"authorization: Bearer {token}",
        \   $"accept: application/json",
        \   $"content-type: application/json",
        \   $"copilot-integration-id: vscode-chat",
        \   $"editor-version: neovim/0.11.0",
        \]

    return ai#build_curl_cmd(url, "GET", headers)
endf

function! s:handle_models_response(_, response, __) abort
    let g:ai_responses += a:response

    let copilot_dir = $"{ai#nvim_get_dir()}/providers/copilot"

    if !filereadable(copilot_dir)
        call mkdir(copilot_dir, "p")
    endi

    let models_json_path = $"{copilot_dir}/models.json"
    return a:response->writefile(models_json_path)
endf

function! s:build_submit_chat_curl_cmd(messages) abort
    if type(a:messages) != v:t_list
        throw "a:messages must be a list"
    endi

    let url = "https://api.githubcopilot.com/chat/completions"

    let system_prompt = "I am sending you a markdown of our chat conversation. Use the previous interactions as context but focus on answering the most recent questions which will be at the bottom of the chat. Never print emojis. I will ask you for code. Only respond with the code in markdown codeblocks. If I want more details I will ask you to clarify. Always limit the width of your output to 80 characters when reasonable."

    let messages = [
        \   { 'role': 'system', 'content': system_prompt },
        \   { 'role': 'user', 'content': a:messages->join("\n") }
        \]

    let body = json_encode(#{
        \   temperature: 0.1,
        \   n: 1,
        \   messages: messages,
        \   max_tokens: 16384,
        \   stream: v:true,
        \   top_p: 1,
        \   model: g:ai_model
        \})

    let token = s:get_token()

    let headers = [
        \   $"authorization: Bearer {token}",
        \   $"accept: application/json",
        \   $"content-type: application/json",
        \   $"copilot-integration-id: vscode-chat",
        \   $"editor-version: neovim/0.11.0",
        \   $"content-length: {len(body)}",
        \]

    return ai#build_curl_cmd(url, "POST", headers, body)
endf

function! providers#copilot#enqueue_chat_submission() abort

    let header = ['', $"# AI.NVIM {g:ai_model}", '', '']

    call appendbufline(bufnr(), "$", header)

    return ai#enqueue_job(#{
        \ cmd: s:build_submit_chat_curl_cmd(getline(0, '$')),
        \ on_stdout: function('s:handle_chat_response'),
        \ })
endf

let s:incomplete_response = ""

function! s:handle_chat_response(_, response, __) abort
    let g:ai_responses += a:response

    let response = a:response

    if response[0]->match('unauthorized: token expired') != -1
        call providers#copilot#enqueue_token_fetch()
        return
    endi

    let data = ""

    for line_nr in range(len(response))

        if response[line_nr] == 'data: [DONE]'
            call appendbufline(bufnr(), "$", ['', '# ME', ''])
            return
        endi

        if s:incomplete_response != ""
            let response[line_nr] = s:incomplete_response . response[line_nr]
            let s:incomplete_response = ""
        endi

        " [-1] wasn't working to get the final character in the line
        let length = len(response[line_nr]) - 1
        if response[line_nr][length] != '}'
            let s:incomplete_response = response[line_nr]
            continue
        endi

        let json = response[line_nr]
            \ ->substitute('^data: ', '', '')

        let json = json_decode(json)

        if empty(json.choices)
           continue
        endi

        if type(json.choices[0].delta.content) != v:t_string
            continue
        endi

        let content = json.choices[0].delta.content
        let last_line = getbufline(bufnr(), "$")[0]

        if content =~ "\n"
            let parts = split(content, "\n", 1)
            call setbufline(bufnr(), "$", last_line . parts[0])
            call appendbufline(bufnr(), "$", parts[1:])
        else
            call setbufline(bufnr(), "$", last_line . content)
        endif
    endfo
endf

function! providers#copilot#get_models() abort
    if s:models_needed()
        call providers#copilot#enqueue_token_fetch()
        call providers#copilot#enqueue_models_fetch()
        call ai#run_job_queue()
        call ai#wait_for_jobs()
    endi

    return $"{ai#nvim_get_dir()}/providers/copilot/models.json"
        \ ->readfile()
        \ ->json_decode()
        \ ->get('data')
        \ ->copy()
        \ ->filter({_, v -> v.model_picker_enabled})
        \ ->map({_, v -> v.id})
        \ ->sort()
endf
