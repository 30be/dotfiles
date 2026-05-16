# See https://www.nushell.sh/book/configuration.html

$env.config = {
    show_banner: false
}
$env.PROMPT_COMMAND_RIGHT = { "" }
use ~/.config/nushell/git-completions.nu *

# From bash
#
$env.config.show_banner = false
$env.config.rm.always_trash = true

# Aliases
alias vi = nvr
alias nvim = nvr
alias vimdiff = nvim -d
alias idrive = /opt/IDriveForLinux/bin/idrive
alias l = ls -a
alias ils = timg --grid=3x1 --upscale=i --center --title -bgray -Bdarkgray
alias printit = lp -d Samsung_SCX-3400_Series
alias runhs = runhaskell --ghc-arg="-package containers" --ghc-arg="-package bytestring"
alias yay = paru

# Functions
def gem [...args] { gemini -m "gemini-3-pro-preview" ...$args }
def flash [...args] { gemini -m "gemini-3-flash" ...$args }

def chaddr [] {
    sudoedit /usr/local/etc/xray/config.json
    sudo systemctl restart xray
}

def --env push [] {
    git add -A
    git commit -m 'something'
    git push
}

def --env mkcd [path: string] {
    mkdir $path
    cd $path
}

def --env tempe [dir?: string] {
    let tmp = (mktemp -d)
    chmod -R 0700 $tmp
    cd $tmp
    if $dir != null {
        mkdir $dir
        cd $dir
        chmod -R 0700 .
    }
    logger -t tempe $"Created and entered: (pwd)"
}

# For nvim

def py [] {
    python3 -c "import sys; exec(sys.stdin.read())"
}

use std/config *

# Initialize the PWD hook as an empty list if it doesn't exist
$env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []

$env.config.hooks.env_change.PWD ++= [{||
  if (which direnv | is-empty) {
    return # If direnv isn't installed, do nothing
  }

  direnv export json | from json | default {} | load-env
  # If direnv changes the PATH, it will become a string and we need to re-convert it to a list
  $env.PATH = do (env-conversions).path.from_string $env.PATH
}]

$env.config.shell_integration = {
    osc7: true,
    osc2: true,
    osc8: true,
}
$env.config.use_kitty_protocol = true

plugin use query
# plugin use polars
# plugin use highlight
# plugin use image
load-env (open ~/.env | parse "{key}={value}" | transpose -rd)

# Carapace external completer
$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

let carapace_completer = {|spans: list<string>|
    let expanded_alias = (scope aliases | where name == $spans.0 | get -o 0.expansion)
    let spans = if $expanded_alias != null {
        $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
    } else {
        $spans
    }
    carapace $spans.0 nushell ...$spans | from json
}

$env.config.completions.external = {
    enable: true
    completer: $carapace_completer
}


$env.config.hooks.command_not_found = {|cmd| try { pkgfile $cmd } catch { null } }
source ~/.zoxide.nu
