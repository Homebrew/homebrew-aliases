# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/aliases"

module Homebrew
  module_function

  def alias_args
    Homebrew::CLI::Parser.new do
      usage_banner "`alias` [<alias> ... | <alias>=<command>]"
      description <<~EOS
        Show existing aliases. If no aliases are given, print the whole list.
      EOS
      switch "--edit",
             description: "Edit aliases in a text editor. Either one or all aliases may be opened at once." \
                        " If the given alias doesn't exist it'll be pre-populated with a template."
      named_args max: 1
    end
  end

  def alias
    args = alias_args.parse

    arg = args.named.first
    split_arg = arg.split("=", 2) if arg.present?

    Aliases.init

    if args.edit?
      if arg.blank?
        Aliases.edit_all
      else
        Aliases.edit arg
      end
    elsif /.=./.match?(arg)
      Aliases.add(*split_arg)
    elsif arg.present?
      Aliases.show arg
    else
      Aliases.show
    end
  end
end
