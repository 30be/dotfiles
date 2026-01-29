$env.HISTSIZE = 1000
$env.EDITOR = "nvim"
$env.TIMG_DEFAULT_TITLE = "%b (%wx%h)"

$env.PATH = ($env.PATH | prepend [
    $"($env.HOME)/bin"
    $"($env.HOME)/.ghcup/bin"
    $"($env.HOME)/.local/bin"
] | uniq)
