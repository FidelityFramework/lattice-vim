# Ionide for F# (Native) - Vim/Neovim

**F# Native Language Support for Vim and Neovim**

A fork of [Ionide-Vim](https://github.com/ionide/Ionide-vim) enhanced for native F# development with the Fidelity framework.

## Overview

Ionide for F# (Native) provides rich IDE support for native F# compilation in Vim/Neovim, powered by [FsNativeAutoComplete (FSNAC)](https://github.com/FidelityFramework/FsNativeAutoComplete).

While the original Ionide-Vim assumes .NET projects, Ionide.FsNative understands:

- **`.fidproj`** - Native F# project manifests (TOML format)
- **`.fsnx`** - Native F# script files
- **Native type semantics** - UTF-8 strings, value-type options, platform words

## Requirements

- Neovim 0.5+ (for built-in LSP) or Vim 8+ with LanguageClient-neovim
- .NET SDK 9.0+ (for FSNAC with FNCS support)

## Installation

### vim-plug

```vim
Plug 'FidelityFramework/Ionide-vim-fsnative'
```

### packer.nvim

```lua
use 'FidelityFramework/Ionide-vim-fsnative'
```

### lazy.nvim

```lua
{ "FidelityFramework/Ionide-vim-fsnative" }
```

## Features

- Syntax highlighting
- Auto completions
- Error highlighting and quick fixes
- Tooltips with type information
- Go to Definition
- Find all references
- CodeLens support
- F# Interactive integration
- Native project support (.fidproj)

### Native-Specific Features

For `.fidproj` projects:
- **Native type display** - See UTF-8 string layout, voption semantics
- **SRTP resolution** - View resolved trait implementations
- **FS8xxx diagnostics** - Native-specific error codes

## Configuration

```vim
" Path to FSNAC (if not in PATH)
let g:fsharp#fsautocomplete_command = ['dotnet', 'fsnac']

" Enable automatic workspace initialization
let g:fsharp#automatic_workspace_init = 1

" Enable LSP auto-setup (Neovim 0.5+)
let g:fsharp#lsp_auto_setup = 1
```

### Neovim Lua Configuration

```lua
require('fidelity').setup({
    cmd = { 'dotnet', 'fsnac' },
    -- Additional LSP settings
})
```

## Commands

| Command | Description |
|---------|-------------|
| `:FSharpReloadWorkspace` | Reload all projects |
| `:FSharpShowLoadedProjects` | Show loaded projects |
| `:FSharpLoadProject <path>` | Load a specific project |
| `:FsiEval <expr>` | Evaluate expression in FSI |
| `:FsiEvalBuffer` | Send buffer to FSI |
| `:FsiShow` | Toggle FSI window |

## Project Files

### Standard (.fsproj)

Works like Ionide-Vim - MSBuild project files with NuGet dependencies.

### Native (.fidproj)

TOML-based project manifests:

```toml
[package]
name = "my_project"

[dependencies]
alloy = { path = "../alloy/src" }

[build]
sources = ["Program.fs"]
output = "my_project"
```

## The Fidelity Ecosystem

| Project | Role |
|---------|------|
| [Firefly](https://github.com/FidelityFramework/Firefly) | AOT compiler |
| [FSNAC](https://github.com/FidelityFramework/FsNativeAutoComplete) | Language server |
| [Ionide.FsNative-VSCode](https://github.com/FidelityFramework/ionide-vscode-fsnative) | VS Code extension |
| **Ionide.FsNative-Vim** | This plugin |
| [Alloy](https://github.com/FidelityFramework/Alloy) | Native standard library |

## Acknowledgments

This project is a fork of [Ionide-Vim](https://github.com/ionide/Ionide-vim). We're grateful to the Ionide maintainers for creating the foundation.

## License

MIT License - see [LICENSE.md](LICENSE.md)
