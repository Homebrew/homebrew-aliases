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

Note that some commands are reserved and can’t be aliases (Homebrew core
commands as well as `alias` and `unalias`).

## Notes

This is an early release, while the usage shown above won’t change, some
details listed below might change in the future:

All aliases are prefixed with `brew`:

    # this won't work
    $ brew alias up="update && upgrade"

    # this will
    $ brew alias up="update && brew upgrade"

Aliases can include aliases:

    $ brew alias show=info
    $ brew alias print=show
    $ brew print git # will run 'brew info git'
