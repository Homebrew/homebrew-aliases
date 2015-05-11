# Homebrew Aliases

This tap allows you to alias your [Homebrew](http://brew.sh/) commands.

## Install

    brew tap bfontaine/aliases

## Usage

This works similar to the `alias` command:

    # add aliases
    $ brew alias up="update"
    $ brew alias i="install"

    # print all aliases
    $ brew alias

    # print one alias
    $ brew alias up

    # use your aliases like any other command
    $ brew i git

    # remove an alias
    $ brew unalias i

Note that some commands are reserved and can’t be aliased (Homebrew core
commands as well as `alias` and `unalias`).

## Notes

This is an early release, while the usage shown above won’t change, some
details listed below might change in the future:

All aliases are prefixed with `brew`, unless they start with `!`:

    # 'brew up' -> 'brew update'
    $ brew alias up=update

    # 'brew status' -> 'git status'
    $ brew alias status="!git status"

Aliases can include other aliases:

    $ brew alias show=info
    $ brew alias print=show
    $ brew print git # will run 'brew info git'
