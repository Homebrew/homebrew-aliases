# -*- coding: UTF-8 -*-

require "pathname"
require "extend/string"

BASE_DIR = File.expand_path "~/.brew-aliases"
RESERVED = HOMEBREW_INTERNAL_COMMAND_ALIASES.keys + \
  Dir["#{HOMEBREW_LIBRARY_PATH}/cmd/*.rb"].map { |cmd| File.basename(cmd, ".rb") } + \
  %w[alias unalias]

module Aliases
  class Alias
    attr_accessor :name, :command

    def initialize(name, command=nil)
      @name = name.strip

      unless command.nil?
        if command.start_with? "!"
          command = command[1..-1]
        else
          command = "brew #{command}"
        end
      end
      @command = command
    end

    def reserved?
      RESERVED.include? name
    end

    def cmd_exists?
      path = which("brew-#{name}.rb") || which("brew-#{name}")
      !path.nil? && path.realpath.parent.to_s != BASE_DIR
    end

    def script
      @script ||= Pathname.new("#{BASE_DIR}/#{name.gsub(/\W/, "_")}")
    end

    def symlink
      @symlink ||= Pathname.new("#{HOMEBREW_PREFIX}/bin/brew-#{name}")
    end

    def valid_symlink?
      symlink.realpath.parent.to_s == BASE_DIR
    rescue NameError
      false
    end

    def write
      if reserved?
        puts "'#{name}' is a reserved command. Sorry."
        exit 1
      end

      if cmd_exists?
        puts "'brew #{name}' already exists. Sorry."
        exit 1
      end

      script.open("w") do |f|
        f.write <<-EOF.undent
          #! #{`which bash`.chomp}
          # alias: brew #{name}
          #{command} $*
        EOF
      end
      script.chmod 0744
      FileUtils.ln_sf script, symlink
    end

    def remove
      unless symlink.exist? && valid_symlink?
        puts "'brew #{name}' is not aliased to anything."
        exit 1
      end

      script.unlink
      symlink.unlink
    end
  end

  class << self
    def init
      FileUtils.mkdir_p BASE_DIR
    end

    def add(name, command)
      Alias.new(name, command).write
    end

    def remove(name)
      Alias.new(name).remove
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
