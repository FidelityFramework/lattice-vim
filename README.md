# lattice-vim

F# Native support for Vim/Neovim

## Heritage

This project is a hard fork of [Ionide-vim](https://github.com/ionide/Ionide-vim), part of the excellent [Ionide](https://ionide.io/) F# IDE tooling ecosystem created by Krzysztof Cieślak.

Lattice extends Ionide's foundation to support polyglot systems programming with F# Native, MLIR, LLVM, F*, Lua, and C. The name "Lattice" represents the chemical progression from individual ions to organized crystal lattices—honoring the foundation while extending to polyglot systems.

See [IONIDE_HERITAGE.md](IONIDE_HERITAGE.md) for complete attribution details.

## Features

- LSP integration for F# Native (.fidproj projects)
- Syntax highlighting
- Code completion
- Go to definition
- Find references
- Inline diagnostics
- Code lens support

## Installation

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'FidelityFramework/lattice-vim'
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use 'FidelityFramework/lattice-vim'
```

## Configuration

In your `init.lua`:

```lua
require('lattice').setup{}
```

Or in `init.vim`:

```vim
lua << EOF
require('lattice').setup{}
EOF
```

## Requirements

- Neovim 0.6.0+ or Vim 8.0+
- [FsAutoComplete](https://github.com/fsharp/FsAutoComplete) LSP server
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) (optional but recommended)

## Acknowledgments

We are deeply grateful to:
- **Krzysztof Cieślak** for creating Ionide and Ionide-vim
- The entire Ionide community for demonstrating what great F# tooling can be
- All contributors to the F# ecosystem

## License

MIT License - see [LICENSE.md](LICENSE.md)
