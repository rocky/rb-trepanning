require_relative 'base_cmd'
class Debugger::Command::StepCommand < Debugger::Command

  unless defined?(HELP)
    HELP = 
"step[+|-|<|>|!] [EVENT-NAME...] [count]
Execute the current line, stopping at the next event.

With an integer argument, step that many times.

EVENT-NAME... is list of an event name which is one on 'call',
'return', 'line', 'exception' 'c-call', 'c-return' or 'c-exception'.
If specified, only those stepping events will be considered. If no
list of event names is given, then any event triggers a stop when the
count is 0.

There is however another way to specify an *single* EVENT-NAME, by
suffixing one of the symbols '<', '>', or '!' after the command or on
an alias of that.  A suffix of '+' on a command or an alias forces a
move to another line, while a suffix of '-' disables this requirement.
A suffix of '>' will continue until the next call. ('finish' will run
run until the return for that call.)

If no suffix is given, the debugger setting 'different-line'
determines this behavior.

Examples: 
  step        # step 1 event, *any* event 
  step 1      # same as above
  step 5/5+0  # same as above
  step line   # step only line events
  step call   # step only call events
  step>       # same as above
  step call line # Step line *and* call events

Related and similar is the 'next' command.  See also the commands:
'skip', 'jump' (there's no 'hop' yet), 'continue', 'return' and
'finish' for other ways to progress execution."

    ALIASES      = %w(s)
    CATEGORY     = 'running'
    MIN_ARGS     = 0   # Need at least this many
    MAX_ARGS     = 1   # Need at most this many
    NAME         = File.basename(__FILE__, '.rb')
    NEED_STACK   = true
    SHORT_HELP   = 'Step program (possibly entering called functions)'
  end

  # This method runs the command
  def run(args) # :nodoc
    if args.size == 1
      # Form is: "step" which means "step 1"
      @proc.core.step_count = 1
    else
      count_str = args[1]
      opts = {
        :msg_on_error => 
        "The 'step' command argument must eval to an integer. Got: %s" % 
        count_str,
        :min_value => 1
      }
      count = @proc.get_an_int(count_str, opts)
      return unless count
      # step 1 is core.step_count = 0 or "stop next event"
      @proc.core.step_count = count - 1  
    end
    @proc.leave_cmd_loop  = true  # Break out of the processor command loop.
  end
end

if __FILE__ == $0
  require_relative %w(.. mock)
  dbgr = MockDebugger.new
  cmds = dbgr.core.processor.instance_variable_get('@commands')
  name = File.basename(__FILE__, '.rb')
  cmd = cmds[name]
  def cmd.msg(message)
    puts message
  end
  p cmd.run([name])
end