require("plenary.busted")

describe(":Ai command", function()

    after_each(function()
        local current_buf = vim.api.nvim_get_current_buf()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if bufnr ~= current_buf and vim.api.nvim_buf_is_loaded(bufnr) then
                vim.api.nvim_buf_delete(bufnr, { force = true })
            end
        end
        vim.cmd("silent! only")
    end)

    it("opens a new horizontal window", function()
        local wins_before = vim.api.nvim_list_wins()
        local height_before = vim.api.nvim_win_get_height(0)

        vim.cmd('Ai')

        local wins_after = vim.api.nvim_list_wins()
        local height_after = vim.api.nvim_win_get_height(0)

        assert(#wins_before == #wins_after - 1)
        assert(height_after < height_before, "Expected a horizontal split")
    end)

    it("creates a new buffer", function()
        local bufs_before = vim.api.nvim_list_bufs()

        vim.cmd('Ai')

        local bufs_after = vim.api.nvim_list_bufs()

        assert(#bufs_before == #bufs_after - 1)
    end)

    it("opens a new vertical window", function()
        local wins_before = vim.api.nvim_list_wins()
        local width_before = vim.api.nvim_win_get_width(0)

        vim.cmd('vertical Ai')

        local wins_after = vim.api.nvim_list_wins()
        local width_after = vim.api.nvim_win_get_width(0)

        assert(#wins_before == #wins_after - 1)
        assert(width_after < width_before, "Expected a vertical split")
    end)

    it("accepts a prompt as an argument", function()
        assert.has_no.errors(function()
            vim.cmd('Ai make me toast')
        end)
    end)

    it("accepts a prompt as an argument with a vertical prefix", function()
        assert.has_no.errors(function()
            vim.cmd('vertical Ai make me toast')
        end)
    end)

    it("passes the prompt to the buffer", function()
        vim.cmd('Ai make me toast')

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        assert(vim.tbl_contains(lines, "make me toast"))
    end)

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

    it("passes the selected range and arguments to the buffer", function()
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

end)
