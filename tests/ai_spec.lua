require("plenary.busted")

local this_repo = vim.fn.expand('<sfile>:p:h')
local default_mock_dir = this_repo .. "/tests/fixtures/ai.nvim"

local function fixture_dir(test_name)
    return this_repo .. "/tests/fixtures/" .. test_name .. "/ai.nvim"
end

local function readjsonfile(path)
    local stat = vim.uv.fs_stat(path)
    local fd = vim.uv.fs_open(path, "r", tonumber('444', 8))
    local data = vim.uv.fs_read(fd, stat.size):gsub("%z", "")
    vim.uv.fs_close(fd)
    return data
end

local jsonschema = require('tests.jsonschema')

local is_valid_token_json = jsonschema.generate_validator({
    type = "object",
    properties = {
        agent_mode_auto_approval = { type = "boolean" },
        annotations_enabled = { type = "boolean" },
        azure_only = { type = "boolean" },
        blackbird_clientside_indexing = { type = "boolean" },
        chat_enabled = { type = "boolean" },
        chat_jetbrains_enabled = { type = "boolean" },
        code_quote_enabled = { type = "boolean" },
        code_review_enabled = { type = "boolean" },
        codesearch = { type = "boolean" },
        copilotignore_enabled = { type = "boolean" },
        endpoints = {
            type = "object",
            properties = {
                api = { type = "string" },
                ["origin-tracker"] = { type = "string" },
                proxy = { type = "string" },
                telemetry = { type = "string" }
            },
            required = { "api", "origin-tracker", "proxy", "telemetry" }
        },
        expires_at = { type = "number" },
        individual = { type = "boolean" },
        organization_list = {
            type = "array",
            items = { type = "string" }
        },
        prompt_8k = { type = "boolean" },
        public_suggestions = { type = "string" },
        refresh_in = { type = "number" },
        sku = { type = "string" },
        snippy_load_test_enabled = { type = "boolean" },
        telemetry = { type = "string" },
        token = { type = "string" },
        tracking_id = { type = "string" },
        vsc_electron_fetcher_v2 = { type = "boolean" },
        xcode = { type = "boolean" },
        xcode_chat = { type = "boolean" }
    },
    required = {
        "agent_mode_auto_approval", "annotations_enabled", "azure_only", "blackbird_clientside_indexing", "chat_enabled",
        "chat_jetbrains_enabled", "code_quote_enabled", "code_review_enabled", "codesearch", "copilotignore_enabled",
        "endpoints", "expires_at", "individual", "organization_list", "prompt_8k", "public_suggestions", "refresh_in",
        "sku", "snippy_load_test_enabled", "telemetry", "token", "tracking_id", "vsc_electron_fetcher_v2", "xcode",
        "xcode_chat"
    }
})

local is_valid_models_json = jsonschema.generate_validator({
    type = "object",
    properties = {
        data = {
            type = "array",
            items = {
                type = "object",
                properties = {
                    id = { type = "string" },
                    capabilities = {
                        type = "object",
                        properties = {
                            supports = {
                                type = "object",
                                additionalProperties = {
                                    anyOf = {
                                        { type = "boolean" },
                                        { type = "number" }
                                    }
                                }
                            },
                            limits = {
                                type = "object",
                                properties = {
                                    vision = {
                                        type = "object",
                                        properties = {
                                            supported_media_types = {
                                                type = "array",
                                                items = { type = "string" }
                                            },
                                            max_prompt_image_size = { type = "number" },
                                            max_prompt_images = { type = "number" }
                                        },
                                        required = { "supported_media_types", "max_prompt_image_size", "max_prompt_images" }
                                    },
                                    max_prompt_tokens = { type = "number" },
                                    max_context_window_tokens = { type = "number" },
                                    max_output_tokens = { type = "number" },
                                    max_inputs = { type = "number" }
                                },
                                additionalProperties = true
                            },
                            type = { type = "string" },
                            tokenizer = { type = "string" },
                            family = { type = "string" },
                            object = { type = "string" }
                        },
                        required = { "supports", "type", "tokenizer", "family", "object" }
                    },
                    model_picker_enabled = { type = "boolean" },
                    name = { type = "string" },
                    policy = {
                        type = "object",
                        properties = {
                            state = { type = "string" },
                            terms = { type = "string" }
                        },
                        required = { "state", "terms" }
                    },
                    vendor = { type = "string" },
                    object = { type = "string" },
                    version = { type = "string" },
                    preview = { type = "boolean" },
                    model_picker_category = { type = "string" },
                    supported_endpoints = {
                        type = "array",
                        items = { type = "string" }
                    }
                },
                required = { "id", "capabilities", "model_picker_enabled", "name", "vendor", "object", "version", "preview" }
            }
        },
        object = { type = "string" }
    },
    required = { "data", "object" }
})

local is_valid_chat_json = jsonschema.generate_validator({
  type = "object",
  required = { "choices", "created", "id", "model", "system_fingerprint" },
  properties = {
    choices = {
      type = "array",
      items = {
        type = "object",
        required = { "index", "delta" },
        properties = {
          index = { type = "integer" },
          delta = {
            type = "object",
            required = { "content" },
            properties = {
                content = {
                    anyOf = {
                        { type = "string" },
                        { lua_type = "userdata" }
                    }
                },
                role = { type = "string" }
            }
          }
        }
      }
    },
    created = { type = "integer" },
    id = { type = "string" },
    model = { type = "string" },
    system_fingerprint = { type = "string" }
  }
})

vim.g.ai_dir = default_mock_dir

vim.g.ai_localtime = 1763098419

local function teardown()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    vim.cmd("silent! only")

    vim.g.i_am_in_a_test = true

    vim.system({ "git", "clean", "-fq", vim.g.ai_dir, default_mock_dir }):wait()
    vim.system({ "git", "restore", vim.g.ai_dir, default_mock_dir }):wait()
    vim.g.ai_dir = default_mock_dir

    vim.g.ai_test_endpoints = nil
end

local function ai_describe(name, fn)
    describe(name, function()
        after_each(teardown)
        fn()
    end)
end

ai_describe(":Ai", function()

    it("does not error", function()
        assert.has_no.errors(function()
            vim.cmd('Ai')
        end)
    end)

    it("reuses the last chat name", function()
        vim.cmd('Ai')
        local expected = vim.api.nvim_buf_get_name(0)

        vim.cmd('Ai')
        local actual = vim.api.nvim_buf_get_name(0)

        assert.equal(expected, actual)
    end)

    it("reuses the last chat window", function()
        vim.cmd("Ai")
        local expected = vim.api.nvim_get_current_win()

        vim.cmd("Ai")
        local actual = vim.api.nvim_get_current_win()

        assert.are.same(expected, actual)
    end)

    it("puts the cursor at the bottom of the chat", function()
        vim.cmd("Ai")

        local expected = vim.api.nvim_buf_line_count(0)
        local actual = vim.api.nvim_win_get_cursor(0)[1]
        assert.are.same(expected, actual)
    end)

    it("gets a new token if /chat/completions complains about expired token", function()

        vim.g.ai_test_endpoints = {
            ['/chat/completions'] = 'expired.json'
        }

        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        local old_token_json = readjsonfile(token_path)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_token_json = readjsonfile(token_path)
        assert.are.not_same(old_token_json, new_token_json)
        assert(is_valid_token_json(vim.fn.json_decode(new_token_json)))
    end)
end)

ai_describe(":Ai!", function()

    it("does not error", function()
        assert.has_no.errors(function()
            vim.cmd('Ai!')
        end)
    end)

    it("creates a new empty chat", function()
        vim.cmd('Ai')
        local old_name = vim.api.nvim_buf_get_name(0)

        vim.wait(1000)

        vim.cmd('Ai!')
        local new_name = vim.api.nvim_buf_get_name(0)

        assert.not_equal(old_name, new_name)

        local expected = { '# ME', '' }
        local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same(expected, actual)
    end)

    it("reuses the last chat window", function()
        vim.cmd("Ai")
        local expected = vim.api.nvim_get_current_win()

        vim.cmd("Ai!")
        local actual = vim.api.nvim_get_current_win()

        assert.are.same(expected, actual)
    end)

    it("puts the cursor at the bottom of the chat", function()
        vim.cmd("Ai!")

        local expected = vim.api.nvim_buf_line_count(0)
        local actual = vim.api.nvim_win_get_cursor(0)[1]
        assert.are.same(expected, actual)
    end)
end)

ai_describe(":Ai <prompt>", function()

    it("accepts a prompt as an argument", function()
        assert.has_no.errors(function()
            vim.cmd('Ai make me toast')
        end)
    end)

    it("passes <prompt> to the buffer", function()
        vim.cmd('Ai make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "make me toast"))
    end)
end)

ai_describe(":Ai! <prompt>", function()

    it("accepts a prompt as an argument", function()
        assert.has_no.errors(function()
            vim.cmd('Ai! make me toast')
        end)
    end)

    it("passes <prompt> to the buffer", function()
        vim.cmd('Ai! make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "make me toast"))
    end)
end)

ai_describe(":Ai <tab>", function()

    it("completes the first argument with models", function()
        local completion = vim.fn['ai#completion']("", "Ai ", "")

        assert(vim.tbl_contains(completion, "gemini-2.5-pro"))
    end)
end)

ai_describe(":Ai g<tab>", function()

    it("completes with models that start with g", function()
        local expected = {
            'grep',
            'gemini-2.5-pro',
            'gpt-4.1',
            'gpt-4o',
            'gpt-5',
            'gpt-5-codex',
            'gpt-5-mini',
        }

        local actual = vim.fn['ai#completion']("g", "Ai g", "")

        assert.are.same(expected, actual)
    end)
end)

ai_describe(":Ai <model>", function()

    it("sets the model to <model>", function()

        vim.cmd('Ai claude-haiku-4.5')

        assert(vim.g.ai_model, "claude-haiku-4.5")
    end)

    it("does not go to a chat", function()
        local expected_buf = vim.api.nvim_get_current_buf()
        local expected_win = vim.api.nvim_get_current_win()
        vim.cmd('Ai claude-haiku-4.5')
        local actual_buf = vim.api.nvim_get_current_buf()
        local actual_win = vim.api.nvim_get_current_win()

        assert.are.same(expected_buf, actual_buf)
        assert.are.same(expected_win, actual_win)
    end)

    ai_describe("<prompt>", function()
        it("does not pass <model> to the chat", function()

            vim.cmd('Ai claude-haiku-4.5 sample chat')

            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

            assert.are.same({
                "# ME",
                "",
                "sample chat"
            }, lines)
        end)
    end)

    it("<tab> does not complete after first argument", function()
        local completion = vim.fn['ai#completion']("", "Ai dummy ", "")

        assert.same({}, completion)
    end)
end)

ai_describe(":'<,'>Ai", function()

    it("accepts a range without error", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c", "d" })

        assert.has_no.errors(function()
            vim.cmd('1,3Ai')
        end)
    end)

    it("passes the selected range to the buffer", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "De La Soul",
            "Wu-Tang",
            "C-Murder",
            "A Tribe Called Quest",
        })

        vim.cmd('2,3Ai')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "Wu-Tang"))
        assert(vim.tbl_contains(lines, "C-Murder"))
    end)

    it("<prompt> passes the selected range and <prompt> to the buffer", function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "De La Soul",
            "Wu-Tang",
            "C-Murder",
            "A Tribe Called Quest",
        })

        vim.cmd('2,3Ai make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "Wu-Tang"))
        assert(vim.tbl_contains(lines, "C-Murder"))
        assert(vim.tbl_contains(lines, "make me toast"))
    end)

    it("wraps ranges in codeblocks if filetype is set", function()
        vim.cmd('edit /tmp/test.lua')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
        })
        vim.bo.filetype = "lua"

        vim.cmd('1,3Ai')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```lua",
            "line 1",
            "line 2",
            "line 3",
            "```"
        }, lines)
    end)

    it("wraps ranges in codeblocks", function()
        vim.cmd('edit /tmp/test')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
        })
        vim.bo.filetype = ""

        vim.cmd('1,3Ai')

        local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```",
            "line 1",
            "line 2",
            "line 3",
            "```"
        }, actual)
    end)

    it("works for single line ranges", function()
        vim.cmd('edit /tmp/test')
        vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            "line 1",
            "line 2",
            "line 3",
        })

        vim.cmd('2Ai')

        local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```",
            "line 2",
            "```"
        }, actual)
    end)
end)

ai_describe(":vert Ai", function()

    it("accepts a prompt as an argument with a vertical prefix", function()
        assert.has_no.errors(function()
            vim.cmd('vertical Ai make me toast')
        end)
    end)
end)

ai_describe("ai#nvim_get_dir()", function()

    it("returns a normal ai.nvim directory", function()
        vim.g.i_am_in_a_test = nil

        local actual = vim.fn['ai#nvim_get_dir']()
        assert.are_match('.local/state', actual)
    end)

    it("returns the default mock directory under test", function()
        local actual = vim.fn['ai#nvim_get_dir']()
        assert.equal(default_mock_dir, actual)
    end)

    it("returns a specific mock directory under test if specified", function()
        vim.g.ai_dir = this_repo .. "/tests/fixtures/specific-test-case/ai.nvim"
        local actual = vim.fn['ai#nvim_get_dir']()
        assert.equal(vim.g.ai_dir, actual)
    end)
end)

ai_describe("providers#get()", function()

    it("returns a list of providers", function()
        local expected = { "copilot" }
        local actual = vim.fn['providers#get']()
        assert.same(expected, actual)
    end)
end)

ai_describe("providers#get_models()", function()

    it("returns all models for all providers", function()
        local expected = {
            'claude-haiku-4.5',
            'claude-sonnet-4.5',
            'gemini-2.5-pro',
            'gpt-4.1',
            'gpt-4o',
            'gpt-5',
            'gpt-5-codex',
            'gpt-5-mini',
        }

        local actual = vim.fn['providers#get_models']()

        assert.same(expected, actual)
    end)
end)

ai_describe(":Ai gpt-4.1 <prompt>", function()

    it("gets cached token if token is not expired on submit", function()
        vim.g.ai_dir = fixture_dir("non-expired-remote-token")
        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        local old_token_json = readjsonfile(token_path)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_token_json = readjsonfile(token_path)
        assert.are.same(old_token_json, new_token_json)
    end)

    it("gets a new token if token is expired on submit", function()
        vim.g.ai_dir = fixture_dir("expired-remote-token")
        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        local old_token_json = readjsonfile(token_path)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_token_json = readjsonfile(token_path)
        assert.are.not_same(old_token_json, new_token_json)
        assert(is_valid_token_json(vim.fn.json_decode(new_token_json)))
    end)

    it("gets a new token if no token exists on submit", function()
        vim.g.ai_dir = fixture_dir("no-token")

        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"

        assert(vim.fn.filereadable(token_path) == 0)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        assert(vim.fn.filereadable(token_path) == 1)

        local new_token_json = readjsonfile(token_path)

        local token
        assert.has_no.errors(function()
            token = vim.json.decode(new_token_json)
        end)
        assert(is_valid_token_json(token))
    end)

    it("gets a new token if token is malformed on submit", function()
        vim.g.ai_dir = fixture_dir("bad-token")

        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_token_json = readjsonfile(token_path)

        local json

        assert.has_no.errors(function()
            json = vim.json.decode(new_token_json)
        end)

        assert(is_valid_token_json(json))

        assert.is_not_nil(json.expires_at)
    end)

    it("gets new models if token is expired on submit", function()
        vim.g.ai_dir = fixture_dir("expired-remote-token-get-models")

        local models_path = vim.g.ai_dir .. "/providers/copilot/models.json"
        local old_models_mtime = vim.uv.fs_stat(models_path).mtime

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_models_mtime = vim.uv.fs_stat(models_path).mtime
        assert.are.not_same(old_models_mtime, new_models_mtime)
    end)

    it("gets new models if no token exists on submit", function()
        vim.g.ai_dir = fixture_dir("no-token-get-models")

        local models_path = vim.g.ai_dir .. "/providers/copilot/models.json"
        local old_models_mtime = vim.uv.fs_stat(models_path).mtime

        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        assert(vim.fn.filereadable(token_path) == 0)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        local new_models_mtime = vim.uv.fs_stat(models_path).mtime
        assert.are.not_same(old_models_mtime, new_models_mtime)
    end)

    it("gets new models if no models exist on submit", function()
        vim.g.ai_dir = fixture_dir("no-models")

        -- ensure models.json does not exist
        local models_path = vim.g.ai_dir .. "/providers/copilot/models.json"
        assert(vim.fn.filereadable(models_path) == 0)

        vim.cmd('Ai gpt-4.1 wow')
        vim.fn['providers#submit_chat']()

        assert(vim.fn.filereadable(models_path) == 1)

        local new_models_json = readjsonfile(models_path)

        local models
        assert.has_no.errors(function()
            models = vim.json.decode(new_models_json)
        end)

        assert(is_valid_models_json(models))
    end)

    it("populates the chat with a response", function()

        vim.cmd('Ai gpt-4.1 write me a hello world in rust')
        vim.fn['providers#submit_chat']()

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            '# ME',
            '',
            'write me a hello world in rust',
            '',
            '# AI.NVIM gpt-4.1',
            '',
            'Certainly! Here is a simple "Hello, world!" program in Rust:',
            '',
            '```rust',
            'fn main() {',
            '    println!("Hello, world!");',
            '}',
            '```',
            '',
            'To run this:',
            '',
            '1. Save it as `main.rs`.',
            '2. Compile it with `rustc main.rs`.',
            '3. Run the output with `./main` (on Linux/macOS) or `main.exe` (on Windows).',
            '',
            'Let me know if you need more help!',
            '',
            '# ME',
            ''
        }, lines)
    end)

    it("creates ai.nvim dir itself", function()
        vim.g.ai_dir = fixture_dir("no-dir")

        local token_path = vim.g.ai_dir .. "/providers/copilot/token.json"
        assert(vim.fn.filereadable(token_path) == 0)

        local models_path = vim.g.ai_dir .. "/providers/copilot/models.json"
        assert(vim.fn.filereadable(models_path) == 0)

        vim.cmd('Ai gpt-4.1 write me a hello world in lua')
        vim.fn['providers#submit_chat']()

        assert(vim.fn.filereadable(token_path) == 1)
        assert(vim.fn.filereadable(models_path) == 1)
    end)
end)

ai_describe("providers#copilot#get_local_token()", function()

    it("successfully gets oauth_token from apps.json", function()
        local expected = "^ghu_[[:alnum:]]\\{36}$"
        local actual = vim.fn['providers#copilot#get_local_token']()
        assert(vim.fn.match(actual, expected) ~= -1)
    end)
end)

ai_describe("providers#copilot#curl_chat()", function()

    it("errors if message isn't a list", function()
        assert.has.errors(function()
            vim.fn['providers#copilot#curl_chat']("")
        end)
    end)
end)

ai_describe(":Ai log", function()

    it("opens the log.md", function()
        vim.cmd('Ai log')
        assert.are_match("log.md", vim.api.nvim_buf_get_name(0))
    end)
end)

ai_describe(":Ai l", function()

    it("opens the log.md", function()
        vim.cmd('Ai l')
        assert.are_match("log.md", vim.api.nvim_buf_get_name(0))
    end)
end)

ai_describe(":Ai messages", function()

    it("sends the contents of :messages to the chat", function()

        vim.cmd([[
            messages clear
            Ai
            echomsg "test-message-payload"
        ]])

        vim.cmd('Ai messages')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```neovim_messages",
            "test-message-payload",
            "```",
        }, lines)
    end)
end)

ai_describe(":Ai mes", function()

    it("sends the contents of :messages to the chat", function()

        vim.cmd([[
            messages clear
            Ai
            echomsg "test-message-payload"
        ]])

        vim.cmd('Ai mes')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert.are.same({
            "# ME",
            "",
            "```neovim_messages",
            "test-message-payload",
            "```",
        }, lines)
    end)
end)

ai_describe("ai#curl", function()

    describe("for copilot endpoint", function()

        it("/copilot_internal/v2/token returns valid json online", function()

            vim.g.i_am_in_a_test = false

            local response = vim.fn['providers#copilot#curl_remote_token']()

            local token
            assert.has_no.errors(function()
                token = vim.fn.json_decode(response)
            end)

            assert(is_valid_token_json(token))
        end)

        it("/copilot_internal/v2/token returns valid json offline", function()

            local response = vim.fn['providers#copilot#curl_remote_token']()

            local token
            assert.has_no.errors(function()
                token = vim.fn.json_decode(response)
            end)

            assert(is_valid_token_json(token))
        end)

        it("/models returns valid json online", function()

            vim.g.i_am_in_a_test = false

            local response = vim.fn['providers#copilot#curl_models']()

            local models
            assert.has_no.errors(function()
                models = vim.fn.json_decode(response)
            end)

            assert(is_valid_models_json(models))
        end)

        it("/models returns valid json offline", function()

            local response = vim.fn['providers#copilot#curl_models']()

            local models
            assert.has_no.errors(function()
                models = vim.fn.json_decode(response)
            end)

            assert(is_valid_models_json(models))
        end)

        it("/chat/completions returns valid json online", function()

            vim.g.i_am_in_a_test = false

            local response = vim.fn['providers#copilot#curl_chat']({'messages'})

            for line in response:gmatch("[^\r\n]+") do
                local json = line:gsub("^data:%s*", "")
                if json ~= "[DONE]" and json ~= "" then
                    local chat
                    assert.has_no.errors(function()
                        chat = vim.fn.json_decode(json)
                    end)

                    assert(is_valid_chat_json(chat))
                end
            end
        end)

        it("/chat/completion returns valid json offline", function()

            local response = vim.fn['providers#copilot#curl_chat']({'messages'})

            for line in response:gmatch("[^\r\n]+") do
                local json = line:gsub("^data:%s*", "")
                if json ~= "[DONE]" and json ~= "" then
                    local chat
                    assert.has_no.errors(function()
                        chat = vim.fn.json_decode(json)
                    end)

                    assert(is_valid_chat_json(chat))
                end
            end
        end)
    end)
end)

ai_describe("vim.g.ai_test_endpoints", function()

    it("can be used to mock endpoints", function()

        vim.g.ai_test_endpoints = {
            ['/chat/completions'] = 'expired.json'
        }
        local response = vim.fn['providers#copilot#curl_chat']({'messages'})

        assert.are_match('unauthorized: token expired', response)
    end)
end)

ai_describe(":Ai", function()

end)

ai_describe(":Ai chats", function()

    it("lists all chats in a quickfix list", function()

        vim.cmd('Ai! chats')

        local qflist = vim.fn.getqflist()

        assert(#qflist > 0)

        local pattern = '.*/ai-chat.*\\.md'

        for _, item in ipairs(qflist) do
            local fname = vim.fn.bufname(item.bufnr)
            assert(vim.fn.match(fname, pattern))
        end
    end)
end)

ai_describe(":Ai grep", function()

    it("<pattern> searches through all chats for <pattern>", function()
        vim.cmd('Ai abc-xyz')
        vim.cmd('silent Ai! grep abc-xyz')
        local qflist = vim.fn.getqflist()
        assert(#qflist == 1)

        local qf_item = qflist[1]
        local bufnr = qf_item.bufnr
        local lnum = qf_item.lnum
        local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
        assert(string.find(line, "abc-xyz", 1, true))
    end)
end)
