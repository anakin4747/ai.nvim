require("plenary.busted")

describe(":Ai command", function()

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

end)
