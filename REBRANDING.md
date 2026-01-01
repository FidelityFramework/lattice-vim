# Fidelity Vim/Neovim Plugin - Rebranding Plan

## Overview

Transform Ionide-vim into Fidelity-vim, a Vim/Neovim plugin for F# native development.

## Directory Structure Changes

```
Current:                    New:
lua/ionide/                → lua/fidelity/
  init.lua                   init.lua
  util.lua                   util.lua
autoload/fsharp.vim        → autoload/fidelity.vim (+ keep fsharp.vim for compat)
plugin/ionide.vim          → plugin/fidelity.vim
```

## Configuration Variable Changes

| Current | New |
|---------|-----|
| `g:fsharp#fsac_path` | `g:fidelity#fsnac_path` |
| `g:fsharp#backend` | `g:fidelity#backend` |
| `g:fsharp#lsp_auto_setup` | `g:fidelity#lsp_auto_setup` |
| `g:fsharp#workspace_mode_peek_deep_level` | `g:fidelity#workspace_mode_peek_deep_level` |
| `g:fsharp#fsi_*` | `g:fidelity#fsi_*` |
| `g:ionide_*` | `g:fidelity_*` |

## Lua Module Changes

```lua
-- Current
lua ionide = require("ionide")

-- New
lua fidelity = require("fidelity")
```

## File Type Detection

Add to `ftdetect/fsharp.vim`:
```vim
" Native project files
au BufNewFile,BufRead *.fidproj setf toml
au BufNewFile,BufRead *.fsnx setf fsharp
```

## LSP Server Configuration

Update `lua/fidelity/init.lua`:
```lua
-- Default to FSNAC instead of FSAC
local default_cmd = { "dotnet", "fsnac" }
-- Or for development:
-- local default_cmd = { "/path/to/FsNativeAutoComplete/bin/fsautocomplete" }
```

## Root Pattern Changes

Add `.fidproj` to root detection:
```lua
root_dir = util.root_pattern("*.fidproj", "*.fsproj", "*.sln", ".git")
```

## Commands

| Current | New |
|---------|-----|
| `:FSharpReloadWorkspace` | `:FidelityReloadWorkspace` |
| `:FSharpShowLoadedProjects` | `:FidelityShowLoadedProjects` |
| `:FSharpLoadProject` | `:FidelityLoadProject` |
| `:FSharpUpdateServerConfig` | `:FidelityUpdateServerConfig` |
| `:FsiEval` | `:FsniEval` (for native interactive) |

## Plugin Manager Installation

```vim
" vim-plug
Plug 'FidelityFramework/fidelity-vim-fsharp'

" packer.nvim
use 'FidelityFramework/fidelity-vim-fsharp'

" lazy.nvim
{ "FidelityFramework/fidelity-vim-fsharp" }
```

## Backward Compatibility

Maintain aliases for transition:
```vim
" In autoload/fsharp.vim
" Delegate to new functions for compatibility
function! fsharp#loadConfig()
    return fidelity#loadConfig()
endfunction
```
