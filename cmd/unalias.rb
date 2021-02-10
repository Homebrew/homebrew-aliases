# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/aliases"

module Homebrew
  module_function

  def unalias_args
    Homebrew::CLI::Parser.new do
      description <<~EOS
        Remove aliases.
      EOS
      named_args :alias, min: 1
    end
  end

  def unalias
    args = unalias_args.parse

    Aliases.init
    args.named.each { |a| Aliases.remove a }
  end
end
