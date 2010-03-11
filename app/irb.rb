# This code comes more or less from ruby-debug.
require 'irb'
module IRB # :nodoc:
  module ExtendCommand # :nodoc:
    # FIXME: should we read these out of a directory to 
    #        make this more user-customizable? 

    # A base command class that resume execution
    class DebuggerResumeCommand
      def self.execute(conf, *opts)
        name = 
          if self.name =~ /IRB::ExtendCommand::(\S+)/
            $1.downcase
          else
            'unknown'
          end
        $rbdbgr_args = opts
        $rbdbgr_command = ([name] + opts).join(' ')
        throw :IRB_EXIT, name.to_sym
      end
    end

    class Continue < DebuggerResumeCommand ; end
    class Next     < DebuggerResumeCommand ; end
    class Quit     < DebuggerResumeCommand ; end
    class Step     < DebuggerResumeCommand ; end

    # Issues a comamnd to the debugger without continuing
    # execution. 
    class Dbgr
      def self.execute(conf, *opts)
        $rbdbgr_command = 
          if opts.size == 1 && opts[0].is_a?(String)
            $rbdbgr_args = opts[0]
          else
            opts.join(' ')
          end
        $rbdbgr.core.processor.run_command($rbdbgr_command)
      end
    end

  end
  if defined?(ExtendCommandBundle)
    [['cont', :Continue],
     ['dbgr', :Dbgr],
     ['n',    :Next],
     ['step', :Step],
     ['q',    :Quit]].each do |command, sym|
      ExtendCommandBundle.def_extend_command command, sym
    end
  end
  
  def self.start_session(binding)
    unless @__initialized

      # Set to run the standard rbdbgr IRB profile
      irbrc = File.expand_path(File.join(File.dirname(__FILE__), 
                                         %w(.. data irbrc)))
      ENV['IRBRC'] = irbrc

      args = ARGV.dup
      ARGV.replace([])
      IRB.setup(nil)
      ARGV.replace(args)
      
      # If the user has a IRB profile, run that now.
      if ENV['RBDBGR_IRB']
        ENV['IRBRC'] = ENV['RBDBGR_IRB']
        @CONF[:RC_NAME_GENERATOR]=nil
        IRB.run_config
      end

      @__initialized = true
    end
    
    workspace = WorkSpace.new(binding)

    irb = Irb.new(workspace)

    @CONF[:IRB_RC].call(irb.context) if @CONF[:IRB_RC]
    @CONF[:MAIN_CONTEXT] = irb.context

    catch(:IRB_EXIT) do
      irb.eval_input
    end
  end
end

if __FILE__ == $0
  # Demo it.
  IRB.start_session(binding) if ARGV.size > 0
end
