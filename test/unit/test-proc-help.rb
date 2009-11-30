#!/usr/bin/env ruby
require 'test/unit'
require_relative %w(.. .. processor help)

# Test Debugger:CmdProcessor
class TestCmdProcessor < Test::Unit::TestCase

  include Debugger::Help
  # See that we have can load up commands
  def test_abbrev_stringify
    assert_equal('(test)ing', 
                 abbrev_stringify('testing', 'test'.size))
  end

end