#:  * `alias` [`--edit`] [<alias> ...]
#:    Show existing aliases. If no aliases are given, print the whole list.
#:
#:    If `--edit` is passed, edit aliases in a text editor. Either one or all
#:    aliases may be open at once. If the given alias doesn't exist it'll be
#:    pre-populated with a template.
#:
#:  * `alias` [`--edit`] <alias>=<command>
#:    Add a new alias.
#:
#:    If `--edit` is passed, edit the newly created <alias> in a text editor.
#:
#:  * `unalias` <alias> [<alias> ...]
#:    Remove aliases.

require "pathname"
require "extend/string"

BASE_DIR = File.expand_path "~/.brew-aliases"
RESERVED = HOMEBREW_INTERNAL_COMMAND_ALIASES.keys + \
           Dir["#{HOMEBREW_LIBRARY_PATH}/cmd/*.rb"].map { |cmd| File.basename(cmd, ".rb") } + \
           %w[alias unalias]

module Aliases
  class Alias
    attr_accessor :name, :command

    def initialize(name, command = nil)
      @name = name.strip

      unless command.nil?
        if command.start_with? "!", "%"
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

    def write(opts = {})
      odie "'#{name}' is a reserved command. Sorry." if reserved?
      odie "'brew #{name}' already exists. Sorry." if cmd_exists?

      return if !opts[:override] && script.exist?

      content = if command
                  "#{command} $*"
                else
                  <<-EOS.undent_________________________________________________________72
                    #
                    # This is a Homebrew alias script. It'll be called when the
                    # user type `brew #{name}`. Any remaining argument is
                    # passed to this script. You can retrieve those with $*, or
                    # the first one only with $1. Please keep your script on
                    # one line.

                    # TODO Replace the line below with your script
                    echo 'Hello I'm brew alias "#{name}" and my args are:' $1
                  EOS
                end

      script.open("w") do |f|
        f.write <<-EOF.undent
          #! #{`which bash`.chomp}
          # alias: brew #{name}
          #{content}
        EOF
      end
      script.chmod 0744
      FileUtils.ln_sf script, symlink
    end

    def remove
      unless symlink.exist? && valid_symlink?
        odie "'brew #{name}' is not aliased to anything."
      end

      script.unlink
      symlink.unlink
    end

    def edit
      write(override: false)
      exec_editor script.to_s
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

    def edit(name, command = nil)
      Alias.new(name, command).write unless command.nil?
      Alias.new(name, command).edit
    end

    def edit_all
      exec_editor(*Dir[BASE_DIR])
    end

    def help
      <<-EOS.undent
        Usage:
          brew alias foo=bar        # set 'brew foo' as an alias for 'brew bar'
          brew alias foo=bar --edit # create alias and edit in EDITOR
          brew alias foo --edit     # open up alias 'foo'in EDITOR
          brew alias foo            # print the alias 'foo'
          brew alias                # print all aliases
          brew alias --edit         # edit all aliases in EDITOR
          brew unalias foo          # remove the 'foo' alias
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
        when "--edit"
          if ARGV[1].nil?
            edit_all
          else
            edit(*ARGV[1].split("=", 2))
          end
        when /.=./
          if ARGV[1] == "--edit"
            edit(*arg.split("=", 2))
          else
            add(*arg.split("=", 2))
          end
        when /./
          if ARGV[1] == "--edit"
            edit arg
          else
            show arg
          end
        else
          show
        end
      end
    end
  end
end

Aliases.cli
