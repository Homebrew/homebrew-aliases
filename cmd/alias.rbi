# typed: strict

class Homebrew::Cmd::Alias
  sig { returns(Homebrew::Cmd::Alias::Args) }
  def args; end
end

class Homebrew::Cmd::Alias::Args < Homebrew::CLI::Args
  sig { returns(T::Boolean) }
  def edit?; end
end
