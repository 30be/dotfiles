$env.HISTSIZE = 1000
$env.EDITOR = "nvr --remote-wait"
$env.TIMG_DEFAULT_TITLE = "%b (%wx%h)"

$env.PATH = ($env.PATH | prepend [
    $"($env.HOME)/bin"
    $"($env.HOME)/.cargo/bin"
    $"($env.HOME)/.ghcup/bin"
    $"($env.HOME)/.local/bin"
    "/usr/lib/ccache/bin"
] | uniq)

# zoxide init nushell | save -f ~/.zoxide.nu
