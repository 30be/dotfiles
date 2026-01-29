# See https://www.nushell.sh/book/configuration.html

$env.config = {
    show_banner: false
}
$env.PROMPT_COMMAND_RIGHT = { "" }


# From bash
#
$env.config.edit_mode = 'vi'
$env.config.show_banner = false
$env.config.rm.always_trash = true

# Aliases
alias vi = nvim
alias vim = nvim
alias vimdiff = nvim -d
alias idrive = /opt/IDriveForLinux/bin/idrive
alias l = ls -a
alias ils = timg --grid=3x1 --upscale=i --center --title -bgray -Bdarkgray
# alias print = lp -d Samsung_SCX-3400_Series
alias runhs = runhaskell --ghc-arg="-package containers" --ghc-arg="-package bytestring"

# Functions
def gem [...args] { proxychains -q gemini -m "gemini-3-pro-preview" ...$args }
def flash [...args] { proxychains -q gemini -m "gemini-3-flash" ...$args }

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

def py [] {
    python3 -c "import sys; exec(sys.stdin.read())"
}
