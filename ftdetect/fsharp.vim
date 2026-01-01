" F#, fsharp
autocmd BufNewFile,BufRead *.fs,*.fsi,*.fsx set filetype=fsharp
autocmd BufNewFile,BufRead *.fsproj         set filetype=fsharp_project syntax=xml

" Fidelity native F# files
autocmd BufNewFile,BufRead *.fsnx           set filetype=fsharp
autocmd BufNewFile,BufRead *.fidproj        set filetype=toml
