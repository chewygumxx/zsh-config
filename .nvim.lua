#!/bin/false
-- vim:set expandtab shiftwidth=4 filetype=lua:
-- SPDX-License-Identifier: GPL-3.0-only

--
--
-- ~chewygumxx/zsh-config.git
-- ::: :/.nvim.lua
--
--

--
-- Project-local Neovim setup: body templates for new files, and completion
-- snippets, scoped by which source directory a buffer's file sits in.
--
-- The filetype stays plain `zsh` throughout. A compound filetype such as
-- `zsh.func` would stop shuck attaching and hide blink's zsh snippets, both
-- of which match the filetype name exactly, and the `filetype=zsh` modeline
-- every file carries would overwrite it on read regardless.
--

---@alias zsh_config.Kind "func" | "wrap" | "util" | "spec"

--- A completion item. Its body is LSP snippet syntax, in which a literal `$`
--- is written `\$`.
---@class zsh_config.Snippet
---@field label string
---@field kinds table<zsh_config.Kind, true>
---@field body  string

-- Resolved from this file rather than from cwd, since exrc also picks up a
-- `.nvim.lua` from any parent of the directory Neovim was started in
local root     = vim.fs.dirname(
    vim.fs.abspath(assert(debug.getinfo(1, "S")).source:sub(2))
)
local root_pat = vim.pesc(root)

--- File name suffix each directory's loader globs for. The empty string
--- means any name, as `func/` and `wrap/` are autoloaded from `fpath`.
---@type table<string, string>
local suffixes = {
    func = "",
    wrap = "",
    util = ".rc.zsh",
    spec = ".spec.zsh",
}

--- Classifies path by the source directory it sits directly within.
---@param path string Absolute path
---@return zsh_config.Kind? kind
---@return string? name          File name without the kind's suffix
local kind_of = function(path)
    local dir, file = path:match("^" .. root_pat .. "/(%l+)/([^/]+)$")
    if not dir or not file or not suffixes[dir] then
        return nil
    end
    ---@cast dir zsh_config.Kind
    local suffix = suffixes[dir]
    if suffix == "" then
        return dir, file
    end
    local name = file:match("^(.+)" .. vim.pesc(suffix) .. "$")
    if name then
        return dir, name
    end
end

--- Escapes text for literal use inside an LSP snippet body.
---@param text string
---@return string
local snippet_escape = function(text)
    return (text:gsub("[%$}\\]", "\\%0"))
end

--
-- Detection
--

-- An extensionless file here has no filetype until its modeline exists,
-- so without this a new one never fires FileType and gets no header
vim.filetype.add({
    pattern = {
        [root_pat .. "/func/[^/]+"] = "zsh",
        [root_pat .. "/wrap/[^/]+"] = "zsh",
    },
})

--
-- Templates
--

-- The `functions_source` form rather than `%N:A`: in an autoloaded
-- function `%N` is the bare function name, so `:A` resolves it against $PWD
local this_file_autoload = "local __this_file="
    .. [=["\${(D)\${functions_source[\${(%):-%N}]:-\${(%):-%N}}}"]=]

--- Body templates, in LSP snippet syntax, with `NAME` standing for the
--- file name without its suffix. The header above them is `util.header`'s.
---@type table<zsh_config.Kind, string>
local templates = {
    func = table.concat({
        "#",
        "# ${1:Description}",
        "#",
        "",
        "emulate -L zsh",
        "",
        this_file_autoload,
        "",
        "$0",
    }, "\n"),

    wrap = table.concat({
        "#",
        "# ${1:Shadow function of NAME}",
        "#",
        "",
        [=[((\$+commands[NAME])) || return 127]=],
        "",
        this_file_autoload,
        "",
        [=[command NAME "\$@"$0]=],
    }, "\n"),

    util = table.concat({
        "#",
        "# ${1:Description}",
        "# ${2:https://}",
        "#",
        "",
        [=[[[ -o interactive ]] || return]=],
        [=[((\$+commands[NAME])) || return]=],
        "",
        [=[local __this_file="\$0"]=],
        "",
        "$0",
    }, "\n"),

    spec = table.concat({
        [=[[[ -o interactive ]] || return]=],
        "",
        [=[local slug="${1:owner}/NAME"]=],
        "$0",
    }, "\n"),
}

local augroup = vim.api.nvim_create_augroup("zsh_config", { clear = true })

-- Scheduled rather than chained off FileType. Filetype detection is itself
-- a BufNewFile autocmd, registered before this file is sourced, so FileType
-- has already fired by the time this callback runs and a mark set here would
-- never be seen. Once `:edit` returns, detection and nvim-config's header
-- insertion have both run, whichever order they fired in.
vim.api.nvim_create_autocmd("BufNewFile", {
    group    = augroup,
    desc     = "Expands a body template into a new zsh-config source file.",
    callback = function(args)
        local buf        = args.buf
        local kind, name = kind_of(vim.api.nvim_buf_get_name(buf))
        if not kind or not name then
            return
        end
        local body = templates[kind]:gsub("NAME", snippet_escape(name))

        -- vim.snippet.expand works at the cursor of the current buffer
        vim.schedule(function()
            if vim.api.nvim_get_current_buf() ~= buf then
                return
            end
            vim.api.nvim_win_set_cursor(0, {
                vim.api.nvim_buf_line_count(buf),
                0,
            })
            vim.snippet.expand(body)
        end)
    end,
})

--
-- Completion
--

---@param ... zsh_config.Kind
---@return table<zsh_config.Kind, true>
local only = function(...)
    ---@type table<zsh_config.Kind, true>
    local set = {}
    for _, kind in ipairs({ ... }) do
        set[kind] = true
    end
    return set
end

---@type zsh_config.Snippet[]
local snippets = {
    {
        label = "__this_file",
        kinds = only("func", "wrap"),
        body  = this_file_autoload,
    },
    {
        label = "__this_file",
        kinds = only("util", "spec"),
        body  = [=[local __this_file="\$0"]=],
    },
    {
        label = "emulate",
        kinds = only("func", "wrap"),
        body  = "emulate -L zsh",
    },
    {
        label = "cmdguard",
        kinds = only("func", "wrap"),
        body  = [=[((\$+commands[${1:name}])) || return 127]=],
    },
    {
        label = "err",
        kinds = only("func", "wrap"),
        body  = [=[print -u2 -f '%s: [%s] %s\\n' "\$0" "${1:ERROR}" "$2"]=],
    },
    {
        label = "interactive",
        kinds = only("util", "spec"),
        body  = [=[[[ -o interactive ]] || return]=],
    },
    {
        label = "require",
        kinds = only("util", "spec"),
        body  = [=[zsh_dirs_require "\$__this_file" ${1:key} || return 1]=],
    },
    {
        label = "slug",
        kinds = only("spec"),
        body  = [=[local slug="${1:owner}/${2:repo}"]=],
    },
    {
        label = "disabled",
        kinds = only("spec"),
        body  = "local enabled=false",
    },
}

local source_id  = "zsh_config"
local source_mod = "zsh_config.snippets"

-- blink resolves a provider by module name, so the source is served from
-- package.preload rather than from a file on 'runtimepath'
package.loaded[source_mod]  = nil
package.preload[source_mod] = function()
    local item_kind   = vim.lsp.protocol.CompletionItemKind.Snippet
    local item_format = vim.lsp.protocol.InsertTextFormat.Snippet
    local source      = {}

    ---@return table
    source.new = function()
        return setmetatable({}, { __index = source })
    end

    ---@return boolean
    source.enabled = function()
        return kind_of(vim.api.nvim_buf_get_name(0)) ~= nil
    end

    ---@param _        table
    ---@param callback fun(response: table)
    source.get_completions = function(_, _, callback)
        local kind  = kind_of(vim.api.nvim_buf_get_name(0))
        local items = {}
        for _, snippet in ipairs(snippets) do
            if kind and snippet.kinds[kind] then
                items[#items + 1] = {
                    label            = snippet.label,
                    kind             = item_kind,
                    insertText       = snippet.body,
                    insertTextFormat = item_format,
                }
            end
        end
        callback({
            items                  = items,
            is_incomplete_forward  = false,
            is_incomplete_backward = false,
        })
    end

    return source
end

local has_blink, blink   = pcall(require, "blink.cmp")
local has_config, config = pcall(require, "blink.cmp.config")
if has_blink and has_config then
    -- add_source_provider asserts on a duplicate id, which re-sourcing this
    -- file would otherwise trip
    if config.sources.providers[source_id] == nil then
        blink.add_source_provider(source_id, {
            name   = "zsh-config",
            module = source_mod,
        })
        blink.add_filetype_source("zsh", source_id)
    end
end
