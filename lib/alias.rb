module Homebrew
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
          <<~EOS
            #:  * `#{name}` [args...]
            #:    `brew #{name}` is an alias for `#{command}`
            #{command} $*
          EOS
        else
          <<~EOS
            #
            # This is a Homebrew alias script. It'll be called when the
            # user type `brew #{name}`. Any remaining argument is
            # passed to this script. You can retrieve those with $*, or
            # the first one only with $1. Please keep your script on
            # one line.

            # TODO Replace the line below with your script
            echo "Hello I'm brew alias "#{name}" and my args are:" $1
          EOS
        end

        script.open("w") do |f|
          f.write <<~EOS
            #! #{`which bash`.chomp}
            # alias: brew #{name}
            #{content}
          EOS
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
  end
end
