# -*- coding: utf-8 -*-
# Module for reading debugger scripts

## import atexit -- from python

# Our local modules
require_relative 'base_intf'

## require_relative %w(.. io scriptin)
## require_relative %w(.. io dbg_output)

# Interface when reading debugger scripts
class Debugger::ScriptInterface < Debugger::Interface

  DEFAULT_OPTS = {
    :abort_on_error => true,
    :confirm_val    => false,
    :verbose        => false
  }
  
  def initialize(script_name, out=nil, opts={})

    @opts = DEFAULT_OPTS.merge(opts)

    # atexit.register(self.finalize)
    @script_name     = script_name
    @input_lineno    = 0
    @input           = File.new(script_name, 'r')
    super(@input, out, @opts)

    @interactive     = false
  end

  # Closes input. (We don't have an output.)
  def close
    @input.close()
  end

  # Called when a dangerous action is about to be done, to make
  # sure it's okay.
  #
  # Could look also look for interactive input and
  # use that. For now, though we'll simplify.
  def confirm(prompt, default)
    @opts[:default_confirm]
  end

  # Common routine for reporting debugger error messages.
  # 
  def errmsg(msg, prefix="*** ")
    #  self.verbose shows lines so we don't have to duplicate info
    #  here. Perhaps there should be a 'terse' mode to never show
    #  position info.
    mess = if not self.verbose
             location = ("%s:%s: Error in source command file" %
                         [@script_name, @input_lineno])
             "%s%s:\n%s%s" % [prefix, location, prefix, msg]
           else
             "%s%s" % [prefix, msg]
           end
    msg(mess)
    # FIXME: should we just set an flag and report eof? to be more
    # consistent with File and IO?
    raise IOError if @opts[:abort_on_error]
  end

  def finalize(last_wishes=nil)
    # print exit annotation
    # save history
    close
  end

  # Script interface to read a command. `prompt' is a parameter for 
  # compatibilty and is ignored.
  def read_command(prompt='')
    @input_lineno += 1
    line = readline
    if @opts[:verbose]
      location = "%s line %s" % [@script_name, @input_lineno]
      msg('+ %s: %s' % [location, line])
    end
    # Do something with history?
    return line
  end

  # Script interface to read a line. `prompt' is a parameter for 
  # compatibilty and is ignored.
  #
  # Could decide make this look for interactive input?
  def readline(prompt='')
    return input.readline()
  end
end

# Demo
if __FILE__ == $0
  intf = Debugger::ScriptInterface.new(__FILE__)
  line = intf.readline()
  print "Line read: ", line
end