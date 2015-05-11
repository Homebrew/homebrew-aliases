# -*- coding: UTF-8 -*-

require "extend/string"

BASE_DIR = File.expand_path "~/.brew-aliases"

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
      path = to_path target
      File.open(path, "w") do |f|
        f.write <<-EOF.undent
          #! #{`which bash`.chomp}
          # alias: brew #{target}
          brew #{orig} $*
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
        cmd = cmd.chomp.gsub(/^brew /, "")

        if aliases.empty? || aliases.include?(target)
          puts "brew alias #{target}='#{cmd}'"
        end
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
