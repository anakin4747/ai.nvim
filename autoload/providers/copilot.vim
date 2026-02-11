
function! providers#copilot#submit_chat() abort
    if g:ai_job_running
        return
    endi

    if s:token_needed()
        call providers#copilot#enqueue_token_fetch()
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
    let token_json_path = $"{ai#nvim_get_dir()}/providers/copilot/token.json"

    if !filereadable(token_json_path)
        return v:true
    endi

    let token_json = token_json_path->readfile()->join("\n")->json_decode()

    if !exists("token_json.expires_at")
        return v:true
    endi

    if token_json.expires_at < a:localtime
        return v:true
    endi

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

    let system_prompt =<< trim END
        I am sending you a markdown of our chat conversation. Use the previous
        interactions as context but focus on answering the most recent
        questions which will be at the bottom of the chat. Never print emojis.
        I will ask you for code. Only respond with the code in markdown
        codeblocks. If I want more details I will ask you to clarify. Always
        limit the width of your output to 80 characters when reasonable.
    END

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

    let headers = [
        \   $"authorization: Bearer {s:get_token()}",
        \   $"accept: application/json",
        \   $"content-type: application/json",
        \   $"copilot-integration-id: vscode-chat",
        \   $"editor-version: neovim/0.11.0",
        \   $"content-length: {len(body)}",
        \]

    return ai#build_curl_cmd(url, "GET", headers)
endf

function! providers#copilot#enqueue_chat_submission() abort
    return ai#enqueue_job(#{
        \ cmd: s:build_submit_chat_curl_cmd(getline(0, '$')),
        \ on_stdout: function('s:handle_chat_response'),
        \ })
endf

function! s:handle_chat_response(_, response, __) abort
    let g:ai_responses += a:response

    if a:response[0]->match('unauthorized: token expired') != -1
        call providers#copilot#enqueue_token_fetch()
        call providers#copilot#enqueue_chat_submission()
        return
    endi

    let data = ""

    for line in a:response
        if line !~ '^data: ' || line =~ 'DONE'
            continue
        endi

        let json = line
            \ ->substitute('^data: ', '', '')
            \ ->json_decode()

        if empty(json.choices)
           continue
        endi

        if type(json.choices[0].delta.content) != v:t_string
            continue
        endi

        let data .= json.choices[0].delta.content
    endfo

    let lines = ['', $"# AI.NVIM {g:ai_model}", '']

    for line in data
        let lines += [line]
    endfo

    let lines += ['', '# ME', '']

    call appendbufline(bufnr(), "$", lines)
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
