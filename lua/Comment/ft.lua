---@mod comment.ft Language/Filetype detection
---@brief [[
---This module is the core of filetype and commentstring detection and uses the
--- |lua-treesitter| APIs to accurately detect filetype and gives the corresponding
---commentstring, stored inside the plugin, for the filetype/langauge.
---@brief ]]

local A = vim.api

---Common commentstring shared b/w mutliple languages
local M = {
    cxx_l = '//%s',
    cxx_b = '/*%s*/',
    dbl_hash = '##%s',
    dash = '--%s',
    dash_bracket = '--[[%s]]',
    hash = '#%s',
    hash_bracket = '#[[%s]]',
    haskell_b = '{-%s-}',
    fsharp_b = '(*%s*)',
    html = '<!--%s-->',
    latex = '%%s',
    lisp_l = ';;%s',
    lisp_b = '#|%s|#',
}

---Lang table that contains commentstring (linewise/blockwise) for mutliple filetypes
---Structure = { filetype = { linewise, blockwise } }
---@type table<string,string[]>
local L = {
    arduino = { M.cxx_l, M.cxx_b },
    bash = { M.hash },
    bib = { M.latex },
    c = { M.cxx_l, M.cxx_b },
    cabal = { M.dash },
    cmake = { M.hash, M.hash_bracket },
    conf = { M.hash },
    conkyrc = { M.dash, M.dash_bracket },
    cpp = { M.cxx_l, M.cxx_b },
    cs = { M.cxx_l, M.cxx_b },
    css = { M.cxx_b, M.cxx_b },
    cuda = { M.cxx_l, M.cxx_b },
    dhall = { M.dash, M.haskell_b },
    dot = { M.cxx_l, M.cxx_b },
    eelixir = { M.html, M.html },
    elixir = { M.hash },
    elm = { M.dash, M.haskell_b },
    elvish = { M.hash },
    fennel = { M.lisp_l },
    fish = { M.hash },
    fsharp = { M.cxx_l, M.fsharp_b },
    gdb = { M.hash },
    gdscript = { M.hash },
    gleam = { M.cxx_l },
    glsl = { M.cxx_l, M.cxx_b },
    gnuplot = { M.hash, M.hash_bracket },
    go = { M.cxx_l, M.cxx_b },
    graphql = { M.hash },
    groovy = { M.cxx_l, M.cxx_b },
    haskell = { M.dash, M.haskell_b },
    heex = { M.html, M.html },
    html = { M.html, M.html },
    htmldjango = { M.html, M.html },
    idris = { M.dash, M.haskell_b },
    ini = { M.hash },
    java = { M.cxx_l, M.cxx_b },
    javascript = { M.cxx_l, M.cxx_b },
    javascriptreact = { M.cxx_l, M.cxx_b },
    jsonc = { M.cxx_l },
    jsonnet = { M.cxx_l, M.cxx_b },
    julia = { M.hash, '#=%s=#' },
    kotlin = { M.cxx_l, M.cxx_b },
    lidris = { M.dash, M.haskell_b },
    lisp = { M.lisp_l, M.lisp_b },
    lua = { M.dash, M.dash_bracket },
    markdown = { M.html, M.html },
    make = { M.hash },
    mbsyncrc = { M.dbl_hash },
    meson = { M.hash },
    nix = { M.hash, M.cxx_b },
    nu = { M.hash },
    ocaml = { M.fsharp_b, M.fsharp_b },
    plantuml = { "'%s", "/'%s'/" },
    purescript = { M.dash, M.haskell_b },
    python = { M.hash }, -- Python doesn't have block comments
    php = { M.cxx_l, M.cxx_b },
    prisma = { M.cxx_l },
    r = { M.hash }, -- R doesn't have block comments
    readline = { M.hash },
    ruby = { M.hash },
    rust = { M.cxx_l, M.cxx_b },
    scala = { M.cxx_l, M.cxx_b },
    scheme = { M.lisp_l, M.lisp_b },
    sh = { M.hash },
    solidity = { M.cxx_l, M.cxx_b },
    sql = { M.dash, M.cxx_b },
    stata = { M.cxx_l, M.cxx_b },
    svelte = { M.html, M.html },
    swift = { M.cxx_l, M.cxx_b },
    sxhkdrc = { M.hash },
    teal = { M.dash, M.dash_bracket },
    terraform = { M.hash, M.cxx_b },
    tex = { M.latex },
    template = { M.dbl_hash },
    tmux = { M.hash },
    toml = { M.hash },
    typescript = { M.cxx_l, M.cxx_b },
    typescriptreact = { M.cxx_l, M.cxx_b },
    vim = { '"%s' },
    vue = { M.html, M.html },
    xml = { M.html, M.html },
    xdefaults = { '!%s' },
    yaml = { M.hash },
    zig = { M.cxx_l }, -- Zig doesn't have block comments
}

local ft = {}

---Sets a commentstring(s) for a filetype/language
---@param lang string Filetype/Language of the buffer
---@param val string|string[]
---@return table self Returns itself
---@usage [[
---local ft = require('Comment.ft')
---
-----1. Using method signature
----- Set only line comment or both
----- You can also chain the set calls
---ft.set('yaml', '#%s').set('javascript', {'//%s', '/*%s*/'})
---
----- 2. Metatable magic
---ft.javascript = {'//%s', '/*%s*/'}
---ft.yaml = '#%s'
---
----- 3. Multiple filetypes
---ft({'go', 'rust'}, {'//%s', '/*%s*/'})
---ft({'toml', 'graphql'}, '#%s')
---@usage ]]
function ft.set(lang, val)
    L[lang] = type(val) == 'string' and { val } or val --[[ @as string[] ]]
    return ft
end

---Get line/block commentstring for a given filetype
---@param lang string Filetype/Language of the buffer
---@param ctype integer See |comment.utils.ctype|
---@return string _ Commentstring
---@usage [[
---local ft = require('Comment.ft')
---local U = require('Comment.utils')
---print(ft.get(vim.bo.filetype, U.ctype.linewise))
---@usage ]]
function ft.get(lang, ctype)
    local l = L[lang]
    return l and l[ctype]
end

---Get a copy of commentstring(s) for a given filetype
---@param lang string Filetype/Language of the buffer
---@return string[] _ Tuple of { line, block } commentstring
---@usage `require('Comment.ft').lang(vim.bo.filetype)`
function ft.lang(lang)
    return vim.deepcopy(L[lang])
end

---Get a language tree for a given range by walking the parse tree recursively.
---This uses 'lua-treesitter' API under the hood. This can be used to calculate
---language of a particular region which embedded multiple filetypes like html,
---vue, markdown etc.
---
---NOTE: This ignores `tree-sitter-comment` parser, if installed.
---@param tree userdata Parse tree to be walked
---@param range integer[] Range to check for
---{start_row, start_col, end_row, end_col}
---@return userdata _ Returns a |treesitter-languagetree|
---@see treesitter-languagetree
---@see lua-treesitter-core
---@usage [[
---local ok, parser = pcall(vim.treesitter.get_parser, 0)
---assert(ok, "No parser found!")
---local tree = require('Comment.ft').contains(parser, {0, 0, -1, 0})
---print('Lang:', tree:lang())
---@usage ]]
function ft.contains(tree, range)
    for lang, child in pairs(tree:children()) do
        if lang ~= 'comment' and child:contains(range) then
            return ft.contains(child, range)
        end
    end

    return tree
end

---Calculate commentstring with the power of treesitter
---@param ctx CommentCtx
---@return string _ Commentstring
---@see comment.utils.CommentCtx
function ft.calculate(ctx)
    local buf = A.nvim_get_current_buf()
    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    local default = ft.get(A.nvim_buf_get_option(buf, 'filetype'), ctx.ctype)

    if not ok then
        return default
    end

    local lang = ft.contains(parser, {
        ctx.range.srow - 1,
        ctx.range.scol,
        ctx.range.erow - 1,
        ctx.range.ecol,
    }):lang()

    return ft.get(lang, ctx.ctype) or default
end

---@export ft
return setmetatable(ft, {
    __newindex = function(this, k, v)
        this.set(k, v)
    end,
    __call = function(this, langs, spec)
        for _, lang in ipairs(langs) do
            this.set(lang, spec)
        end
        return this
    end,
})
