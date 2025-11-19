
function! providers#copilot#submit_chat() abort
    call s:get_token()
    let response = s:get_chat_data()

    let lines = ['', $"# AI.NVIM {g:ai_model}", '']

    for line in response->split("\n")
        let lines += [line]
    endfo

    let lines += ['', '# ME', '']

    call appendbufline(bufnr(), "$", lines)
endf

function! providers#copilot#get_models() abort
    return s:get_models().data
        \ ->copy()
        \ ->filter({_, v -> v.model_picker_enabled})
        \ ->map({_, v -> v.id})
        \ ->sort()
endf

function! s:get_models() abort
    let models_json_path = $"{ai#nvim_get_dir()}/providers/copilot/models.json"

    if !filereadable(models_json_path)
        call s:save_models()
    endi

    return models_json_path->readfile()->join("\n")->json_decode()
endf

function! s:save_models() abort
    let copilot_dir = $"{ai#nvim_get_dir()}/providers/copilot"

    if !filereadable(copilot_dir)
        call mkdir(copilot_dir, "p")
    endi

    let models_json_path = $"{copilot_dir}/models.json"

    let json = [s:curl_models()->json_encode()]
    return json->writefile(models_json_path)
endf

function! s:curl_models() abort
    if exists("g:copilot_curl_models_mock")
        return g:copilot_curl_models_mock->trim()->json_decode()
    endi

    let copilot_url = "https://api.business.githubcopilot.com/models"
    let token = s:get_token()

    let headers = [
        \   $"authorization: Bearer {token}",
        \   $"accept: application/json",
        \   $"content-type: application/json",
        \   $"copilot-integration-id: vscode-chat",
        \   $"editor-version: neovim/0.11.0",
        \]

    return ai#curl(copilot_url, "GET", headers)->trim()->json_decode()
endf

function! s:get_token(localtime = g:ai_localtime) abort
    let token_json_path = $"{ai#nvim_get_dir()}/providers/copilot/token.json"

    if !filereadable(token_json_path)
        call s:save_remote_token()
        call s:save_models()
        return s:get_token(a:localtime)
    endi

    let token_json = token_json_path->readfile()->join("\n")->json_decode()

    if !exists("token_json.expires_at")
        call s:save_remote_token()
        return s:get_token(a:localtime)
    endi

    if token_json.expires_at > a:localtime
        return token_json.token
    endi

    call s:save_remote_token()
    call s:save_models()
    return s:get_token(a:localtime)
endf

function! providers#copilot#get_local_token() abort
    let apps_json_path = $"{expand("$HOME")}/.config/github-copilot/apps.json"
    let apps_json = apps_json_path->readfile()->join("\n")->json_decode()
    return apps_json[keys(apps_json)[0]]['oauth_token']
endf

function! s:curl_remote_token() abort
    if exists("g:copilot_curl_token_mock")
        return g:copilot_curl_token_mock->trim()->json_decode()
    endi

    let copilot_url = "https://api.github.com/copilot_internal/v2/token"
    let local_token = providers#copilot#get_local_token()

    let headers = [
        \   $"authorization: Bearer {local_token}",
        \   $"accept: application/json",
        \]

    return ai#curl(copilot_url, "GET", headers)->trim()->json_decode()
endf

function! s:save_remote_token() abort
    let copilot_dir = $"{ai#nvim_get_dir()}/providers/copilot"

    if !filereadable(copilot_dir)
        call mkdir(copilot_dir, "p")
    endi

    let token_json_path = $"{copilot_dir}/token.json"

    let json = [s:curl_remote_token()->json_encode()]
    return json->writefile(token_json_path)
endf

function! s:get_new_message() abort
    let lnum = 0
    for i in reverse(range(1, line('$')))
      if getline(i) =~# '^# ME$'
        let lnum = i
        break
      endi
    endfo

    return getline(lnum + 1, '$')
        \ ->join("\n")
        \ ->trim()
endf

function! s:get_chat_data() abort
    let response = s:get_new_message()->s:curl_chat_data()

    let data = ""

    for line in response->split("\n")
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

    return data
endf

function! s:curl_chat_data(message) abort
    if exists("g:copilot_curl_chat_mock")
        return g:copilot_curl_chat_mock
    endi

    let copilot_url = "https://api.business.githubcopilot.com/chat/completions"
    let temperature = 0.1
    let n = 1
    let messages = [
        \   { 'role': 'system', 'content': 'Never print emojis. I will ask you for code. Only respond with the code in markdown codeblocks. If I want more details I will ask you to clarify.'},
        \   { 'role': 'user', 'content': a:message }
        \]
    let max_tokens = 16384
    let stream = v:true
    let top_p = 1
    let model = 'gpt-4.1'

    let body = json_encode(#{
        \   temperature: temperature,
        \   n: n,
        \   messages: messages,
        \   max_tokens: max_tokens,
        \   stream: stream,
        \   top_p: top_p,
        \   model: model
        \})
    let content_length = len(body)

    let token = s:get_token()

    let headers = [
        \   $"authorization: Bearer {token}",
        \   $"accept: application/json",
        \   $"content-type: application/json",
        \   $"copilot-integration-id: vscode-chat",
        \   $"editor-version: neovim/0.11.0",
        \   $"content-length: {content_length}",
        \]

    return ai#curl(copilot_url, "POST", headers, body)
endf
