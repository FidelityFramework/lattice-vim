# lattice-vim

A hard fork of [Ionide-vim](https://github.com/ionide/Ionide-vim), relabelled. What is Lattice's own is about
sixty lines of Lua registering a language server with Neovim's built-in LSP client; the remaining three
thousand lines are Ionide-vim (an FsAutoComplete client, a regex F# syntax file, `dotnet fsi` integration).

**Disposition.** Per the consumer contract (`~/repos/clef/docs/fidelity/phg/Lattice_Consumer_Contract.md`,
§6), this plugin becomes the registration shim it already is, over the Lattice server: root detection on
`.fidproj`, filetypes `.clef`/`.clefx`, semantic tokens from the graph in place of the regex syntax file. The
FSAC-private `fsharp/*` requests, the analyzer settings block, F1 help and the F# Interactive commands are
retired.

The long-form upstream documentation (`README.mkd`, `doc/vim-fsharp.txt`) describes Ionide-vim, not this
plugin, and is retained only until the shim replaces the body.

Upstream license and attribution: see `LICENSE.md`. Ionide-vim is the work of the Ionide community.
