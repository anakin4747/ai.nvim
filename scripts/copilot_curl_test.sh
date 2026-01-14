#!/bin/bash

get_local_token() (
    jq -r '.[].oauth_token' ~/.config/github-copilot/apps.json
)

curl_token() (
    curl \
        --request "GET" \
        --url "https://api.github.com/copilot_internal/v2/token" \
        --header "authorization: Bearer $(get_local_token)" \
        --header "accept: application/json"
)

curl_token_bad_bearer() (
    curl \
        --request "GET" \
        --url "https://api.github.com/copilot_internal/v2/token" \
        --header "authorization: Bearer ghu_eSbDOhsOcy1HPmfLfmvc9z7fj9SpNmhceoyW" \
        --header "accept: application/json"
)

get_session_token() (
    curl_token | jq -r .token
)

curl_models() (
    curl \
        --request "GET" \
        --url "https://api.githubcopilot.com/models" \
        --header "authorization: Bearer $(get_session_token)" \
        --header "accept: application/json" \
        --header "content-type: application/json" \
        --header "copilot-integration-id: vscode-chat" \
        --header "editor-version: neovim/0.11.0"
)

curl_models_bad_session_token() (
    curl \
        --request "GET" \
        --url "https://api.githubcopilot.com/models" \
        --header "authorization: Bearer tid=f02e326f800ee26f04df7961adbf7c0a;ol=f02e326f800ee26f04df7961adbf7c0a;exp=1768172388;sku=copilot_for_business_seat_quota;proxy-ep=proxy.business.githubcopilot.com;st=dotcom;ssc=1;chat=1;sn=1;malfil=1;editor_preview_features=1;agent_mode=1;agent_mode_auto_approval=1;mcp=1;ccr=1;8kp=1;ip=8.8.8.8;asn=AS1403:d3eb539a556352f3f47881d71fb0e5777b2f3e9a4251d283c18c67ce996774b7" \
        --header "accept: application/json" \
        --header "content-type: application/json" \
        --header "copilot-integration-id: vscode-chat" \
        --header "editor-version: neovim/0.11.0"
)

curl_chat() (
    data='{ "temperature": 0.1, "n": 1, "messages": [ { "role": "system", "content": "give me code" }, { "role": "user", "content": "write me hello world in rust" } ], "max_tokens": 16384, "stream": true, "top_p": 1, "model": "gpt-4.1" }'
    curl \
        --request "POST" \
        --url "https://api.githubcopilot.com/chat/completions" \
        --header "authorization: Bearer $(get_session_token)" \
        --header "accept: application/json" \
        --header "content-type: application/json" \
        --header "copilot-integration-id: vscode-chat" \
        --header "editor-version: neovim/0.11.0" \
        --header "content-length: ${#data}" \
        --data "${data}"
)

curl_chat_bad_session_token() (
    data='{ "temperature": 0.1, "n": 1, "messages": [ { "role": "system", "content": "give me code" }, { "role": "user", "content": "write me hello world in rust" } ], "max_tokens": 16384, "stream": true, "top_p": 1, "model": "gpt-4.1" }'
    curl \
        --request "POST" \
        --url "https://api.githubcopilot.com/chat/completions" \
        --header "authorization: Bearer tid=f02e326f800ee26f04df7961adbf7c0a;ol=f02e326f800ee26f04df7961adbf7c0a;exp=1768172388;sku=copilot_for_business_seat_quota;proxy-ep=proxy.business.githubcopilot.com;st=dotcom;ssc=1;chat=1;sn=1;malfil=1;editor_preview_features=1;agent_mode=1;agent_mode_auto_approval=1;mcp=1;ccr=1;8kp=1;ip=8.8.8.8;asn=AS1403:d3eb539a556352f3f47881d71fb0e5777b2f3e9a4251d283c18c67ce996774b7" \
        --header "accept: application/json" \
        --header "content-type: application/json" \
        --header "copilot-integration-id: vscode-chat" \
        --header "editor-version: neovim/0.11.0" \
        --header "content-length: ${#data}" \
        --data "${data}"
)

requests="$(sed -n 's/\(curl_\w\+\)(.*) (/\1/p' < "$0")"

PS3="curl what? "
select request in $requests; do
    $request
    break
done
