require_relative "alias"

module Homebrew
  module Aliases
    BASE_DIR = File.expand_path "~/.brew-aliases"
    RESERVED = Commands::HOMEBREW_INTERNAL_COMMAND_ALIASES.keys + \
               Dir["#{HOMEBREW_LIBRARY_PATH}/cmd/*.rb"].map { |cmd| File.basename(cmd, ".rb") } + \
               %w[alias unalias]

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
        target = meta.chomp.gsub(/^# alias: brew /, "")
        next unless aliases.empty? || aliases.include?(target)

        lines.reject! { |line| line.start_with?("#") || line =~ /^\s*$/ }
        cmd = lines.first.chomp
        cmd.sub!(/ \$\*$/, "")

        if /^brew /.match?(cmd)
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
