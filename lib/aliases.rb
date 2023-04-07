# frozen_string_literal: true

require_relative "alias"

module Homebrew
  module Aliases
    # Unix-Like systems store config in $HOME/.config whose location can be
    # overridden by the XDG_CONFIG_HOME environment variable. Unfortunately
    # Homebrew strictly filters environment variables in BuildEnvironment.
    BASE_DIR = if (path = Pathname.new("~/.config/brew-aliases").expand_path).exist? ||
                  (path = Pathname.new("~/.brew-aliases").expand_path).exist?
      path.realpath
    else
      path
    end.freeze
    RESERVED = (
      Commands::HOMEBREW_INTERNAL_COMMAND_ALIASES.keys +
      Dir["#{HOMEBREW_LIBRARY_PATH}/cmd/*.rb"].map { |cmd| File.basename(cmd, ".rb") } +
      %w[alias unalias]
    ).freeze

    module_function

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
        next if path.end_with? "~" # skip Emacs-like backup files

        _, meta, *lines = File.readlines(path)
        target = meta.chomp.delete_prefix("# alias: brew ")
        next if !aliases.empty? && aliases.exclude?(target)

        lines.reject! { |line| line.start_with?("#") || line =~ /^\s*$/ }
        cmd = lines.first.chomp
        cmd.sub!(/ \$\*$/, "")

        if cmd.start_with? "brew "
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
  end
end
