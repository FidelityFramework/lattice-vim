# lattice-vim

A hard fork of [Ionide-vim](https://github.com/ionide/Ionide-vim), now providing an initial Clef client for Neovim 0.11 or newer. It connects Neovim's built-in LSP client to an explicitly configured server. The .NET-hosted [Lattice service under Composer](https://github.com/FidelityFramework/Composer/tree/main/src/Lattice.Server) now supplies a local CCS-backed VSCode demo; its Neovim semantic gate remains work. The [Lattice integration plan](https://github.com/FidelityFramework/Composer/blob/main/docs/Lattice_Integration.md) coordinates the compiler and editor gates.

## Configure the Neovim client

Add this repository to Neovim's runtime path through your plugin manager, then supply the actual command for a compatible stdio LSP server:

```lua
require('lattice').setup({
  cmd = { 'dotnet', '/absolute/path/to/Composer/src/Lattice.Server/bin/Debug/net10.0/Lattice.Server.dll' },
})
```

Build that DLL from Composer with `dotnet build src/Lattice.Server/Lattice.Server.fsproj`. Replace the absolute prefix with your checkout location. The server selects the one `.fidproj` in the workspace root; add `--project` and its path when several are present. The executable and arguments are passed directly; this plugin does not download a server, add FSAC flags, or select a default command. A missing or invalid command produces a configuration error.

[File detection](ftdetect/clef.vim) registers `.clef` as `clef`. The [client](lua/lattice/init.lua) attaches named Clef buffers beneath the nearest directory containing a `.fidproj`. This is a registration hint: CCS still owns project interpretation, membership, source order and dependencies. Several manifests in one directory do not make the client choose a project. There is no `.git` or working-directory fallback; untitled files and `.clefx` support remain pending.

Standard Neovim LSP handling supplies the capabilities the server advertises, including hover and diagnostics. The client adds no private `fsharp/*` requests or automatic code-lens polling. It does not infer dimensions, assign proof verdicts or reconstruct compiler facts.

Calling `setup` again with the same command is safe. A changed command replaces this plugin's clients. To control their lifetime explicitly:

```lua
require('lattice').restart()
require('lattice').stop() -- disables automatic attachment until setup is called again
```

Restart and reconfiguration request graceful shutdown and wait for client cleanup before replacement; an unresponsive process is stopped after the grace period. Clients for nested project roots remain separate. Renaming a buffer outside its former root detaches it from that client.

The inherited automatic FSAC activation and F# filetype callbacks are disconnected. Opening `.fs` or `.fsproj` does not start an F# server or install FSI commands through this plugin. The retained [F# implementation](autoload/fsharp.vim) is reference material, not a second backend for the Clef client. **Plain Vim integration remains pending**; it is not covered by the Neovim implementation or tests. Clef lexical highlighting and semantic-token coverage also need their own validation; the companion `clef-grammar` repository supplies a TextMate baseline for consumers that support it.

## Transport regression gate

With Neovim 0.11+ and Node.js available, run:

```sh
bash tests/run.sh
```

The gate runs in real headless Neovim against a small [stdio fixture server](tests/fixture-server.mjs). It checks explicit command arguments, file registration, nearest project roots, initialization, document open/change/close, Unicode full-text updates, hover, diagnostic clearing, capability handling, mixed-file isolation and setup/restart/shutdown. It also checks that no FSAC-private or unadvertised code-lens request is sent. The current run was validated with Neovim 0.12.5.

The fixture's `FIXTURE001` diagnostic and hover text test transport only. They are not CCS type checking or proof results. The compiler integration gate remains the shared measured-type fixture: hover preserves dimensional identity, an incompatible-dimension edit produces the compiler's diagnostic, and a correction clears it without stale results replacing current ones. Proof evidence and its invalidation must follow compiler-owned query contracts as they land. Plain Vim needs a separate client gate before claiming support.

## Heritage

The long-form [upstream README](README.mkd) and [Vim help](doc/vim-fsharp.txt) describe the inherited Ionide-vim behavior. Preserve them as heritage rather than using their FSAC commands as Lattice setup instructions. See [IONIDE_HERITAGE.md](IONIDE_HERITAGE.md) and [LICENSE.md](LICENSE.md) for attribution. Ionide-vim is the work of the Ionide community.
