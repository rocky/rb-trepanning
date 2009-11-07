# -*- coding: utf-8 -*-
require_relative %w(.. .. base subsubcmd)

class Debugger::Subcommand::SetAutoList < Debugger::SetBoolSubSubcommand
  unless defined?(HELP)
    HELP = "Set to run a 'list' command each time we enter the debugger"
    MIN_ABBREV = 'l'.size
    NAME       = File.basename(__FILE__, '.rb')
    PREFIX     = %w(set auto list)
  end

  def run(args)
    super
    if @proc.settings[:autolist]
      if @proc.before_cmdloop_hooks.select{|h|
          h[0] == 'autolist'}.empty?
        cmd = @proc.commands['list']
        @proc.before_cmdloop_hooks << 
          ['autolist', 
           lambda{|*args| cmd.run(*args)}, 
           [%w(list .)]]
      end
    else
      @proc.before_cmdloop_hooks = 
        @proc.before_cmdloop_hooks.reject{|h|
          h[0] == 'autolist'}
    end
  end

end

if __FILE__ == $0
  # Demo it.
  require_relative %w(.. .. .. mock)
  require_relative %w(.. .. .. subcmd)
  name = File.basename(__FILE__, '.rb')

  # FIXME: DRY the below code
  dbgr, set_cmd = MockDebugger::setup('set')
  testcmdMgr    = Debugger::Subcmd.new(set_cmd)
  auto_cmd      = Debugger::SubSubcommand::SetAuto.new(dbgr.core.processor, 
                                                       set_cmd)
  # FIXME: remove the 'join' below
  cmd_name      = Debugger::Subcommand::SetAutoList::PREFIX.join('')
  autox_cmd     = Debugger::SubSubcommand::SetAutoList.new(set_cmd.proc, 
                                                           auto_cmd,
                                                           cmd_name)
  # require_relative %w(.. .. .. .. rbdbgr)
  # dbgr = Debugger.new(:set_restart => true)
  # dbgr.debugger
  subcmd_name = Debugger::Subcommand::SetAutoList::PREFIX[1..-1].join('')
  autox_cmd.run([subcmd_name])
  autox_cmd.run([subcmd_name, 'off'])

end