# Tools

## Custom scripts

Every design project has its own set of custom scripts, usually to shoehorn
bytes around into the right format.

## Editor

This was the first project I completed fully in (neo)vim, using the LazyVim set
of plugins. I know, I became the very thing I swore to destroy.

If you do happen to go down that route, though, I used the JetBrains Mono Nerd
Font, which gives full icon support in LazyVim, with the
[Monokai Pro](https://github.com/loctvl842/monokai-pro.nvim) theme [^also]. I
also recommend `mini.align` for aligning SystemVerilog and Prettier for
formatting Markdown, which when coupled with LazyVim's native `lang.markdown`
support leads to an incredible documentation writing experience. I suggest
turning on `proseWrap` specifically for Markdown to keep things nicely limited
at 80 chars per row.

[^also]:
    I also considered the [Alabaster](https://sr.ht/~p00f/alabaster.nvim/) theme
