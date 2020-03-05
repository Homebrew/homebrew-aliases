require "cli/parser"
require_relative "../lib/aliases"

module Homebrew
  module_function

  def unalias_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `unalias` <alias> [<alias> ...]

        Remove aliases.
      EOS
      min_named 1
    end
  end

  def unalias
    unalias_args.parse

    Aliases.init
    ARGV.named.each { |a| Aliases.remove a }
  end
end
