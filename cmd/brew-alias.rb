# -*- coding: UTF-8 -*-

require "extend/string"

BASE_DIR = File.expand_path "~/.brew-aliases"
RESERVED = %w[
  install remove update list search audit cat cleanup commands config create
  deps diy doctor edit fetch home info irb leaves ln link linkapps ls log
  missing options outdated pin prune reinstall rm uninstall search sh switch
  tap test tests unlink unlinkapps unpack unpin untap update upgrade uses
  bottle gist-logs man postinstall readall style tap-readme test-bot cask
  alias unalias]

def to_path s
  "#{BASE_DIR}/#{s.gsub(/\W/, "_")}"
end

module Aliases
  class << self
    include FileUtils

    def init
      mkdir_p BASE_DIR
    end

    def add(target, orig)
      target.strip!

      if RESERVED.include?(target)
        puts "'#{target}' is a reserved command. Sorry."
        exit 1
      end

      if orig =~ /^!/
          orig.sub!(/^!/, "")
      else
          orig = "brew #{orig}"
      end

      path = to_path target
      File.open(path, "w") do |f|
        f.write <<-EOF.undent
          #! #{`which bash`.chomp}
          # alias: brew #{target}
          #{orig} $*
        EOF
      end
      chmod 0744, path
      ln_sf path, "#{HOMEBREW_PREFIX}/bin/brew-#{target}"
    end

    def remove(target)
      rm_f (to_path target)
      rm_f "#{HOMEBREW_PREFIX}/bin/brew-#{target}"
    end

    def show(*aliases)
      Dir["#{BASE_DIR}/*"].each do |path|
        _, meta, cmd = File.readlines(path)
        target = meta.chomp.gsub(/^# alias: brew /, "")
        next unless aliases.empty? || aliases.include?(target)

        cmd.chomp!
        cmd.sub!(/ \$\*$/, "")

        if cmd =~ /^brew /
            cmd.sub!(/^brew /, "")
        else
            cmd = "!#{cmd}"
        end

        puts "brew alias #{target}='#{cmd}'"
      end
    end

    def help
      <<-EOS.undent
        Usage:
          brew alias foo=bar  # set 'brew foo' as an alias for 'brew bar'
          brew alias foo      # print the alias 'foo'
          brew alias          # print all aliases
          brew unalias foo    # remove the 'foo' alias
      EOS
    end

    def print_help_and_exit
      puts help
      exit
    end

    def cli
      init
      arg = ARGV.first
      print_help_and_exit if %w[help -h -help --help].include? arg

      if __FILE__ =~ /unalias/
        print_help_and_exit if ARGV.empty?
        ARGV.each { |a| remove a }
      else
        case arg
        when /.=./
          add(*arg.split("=", 2))
        when /./
          show arg
        else
          show
        end
      end
    end

  end
end

Aliases.cli
