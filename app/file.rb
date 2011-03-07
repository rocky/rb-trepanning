# -*- coding: utf-8 -*-
# Copyright (C) 2010 Rocky Bernstein <rockyb@rubyforge.net>
# Things related to file/module status
require 'thread_frame'

SCRIPT_ISEQS__ = {} unless 
  defined?(SCRIPT_ISEQS__) && SCRIPT_ISEQS__.is_a?(Hash)
ISEQS__        = {} unless 
  defined?(ISEQS__) && ISEQS__.is_a?(Hash)

module Trepanning
  def file_match_pat(filename)
    prefix = 
      if filename[0..0] == File::SEPARATOR
        # An absolute filename has to match at the beginning and
        # the end.
        '^'
      else
        # An nonabsolute filename has to match either at the
        # beginning of the file name or have a path separator before
        # the supplied part, e.g. "file.rb" does not match "myfile.rb"
        # but matches "my/file.rb"
        '(?:^|[/])'
      end
    "#{prefix}#{Regexp.escape(filename)}$"
  end

  def filter_scripts(dirname)
    match_block = Proc.new{|filename, iseq| filename =~ /^#{dirname}/}
    scripts = SCRIPT_ISEQS__.select(&match_block)
    SCRIPT_ISEQS__.delete_if(&match_block)
    match_block = Proc.new{|iseq| 
      iseq.source_container[1] =~ /^#{dirname}/
    }
    rejected = {}
    # SCRIPT_ISEQS__ is updated automatically.  Dup copy is to make
    # sure we we aren't iterating over something that some other
    # process, thread or hook is filling.
    script_iseqs = SCRIPT_ISEQS__.dup
    script_iseqs.each do |name, iseqs|
      ary = iseqs.select(&match_block)
      rejected[name] = ary unless ary.empty?
      iseqs.delete_if(&match_block)
    end
    return [scripts, rejected]
  end

  def find_scripts(filename)
    filename_pat = file_match_pat(filename)
    return SCRIPT_ISEQS__.keys.grep(/#{filename_pat}/)
  end

  def find_iseqs(iseqs_hash, name)
    iseq_name, filename = name.split(/@/)
    return [] unless iseqs_hash.member?(iseq_name)
    iseqs = iseqs_hash[iseq_name]
    # FIXME: filter out debugger iseqs
    if filename
      filename_pat = file_match_pat(filename)
      iseqs.select{|iseq| iseq.source_container[1] =~ /#{filename_pat}/}
    else
      return iseqs 
    end
  end

  # Returns a RubyVM::Instruction for the specified line. We search the
  # current instruction sequence +iseq+ and then up the parent scope.  If we hit
  # the top and we can't find +line+ that way, then we
  # reverse the search from the top and search down. This will add
  # all siblings of ancestors of +meth+.
  # Similar to rbx-trepanning method "find_method_with_line".
  def find_iseq_with_line_from_iseq(iseq, lineno, go_up=true)
    find_iseq_with_line_from_iseq2(iseq, lineno, go_up, {})
  end

  def find_iseq_with_line_from_iseq2(iseq, lineno, go_up, seen)
    return iseq if iseq.offsetlines.values.flatten.uniq.member?(lineno)
    seen[iseq] = true
    prev_iseq = iseq
    while prev_iseq = prev_iseq.parent
      iseq = prev_iseq
      return iseq if iseq.offsetlines.values.flatten.uniq.member?(lineno)
    end if go_up
    # At top and not found so now go down..
    iseq.child_iseqs.each do |child_iseq|
      next if seen[child_iseq] # we tried before
      # puts "#{child_iseq.name}, #{child_iseq}"
      result = find_iseq_with_line_from_iseq2(child_iseq, lineno, false, seen)
      return result if result
    end
    return nil
  end

  def find_iseqs_with_lineno(filename, lineno)
    files = find_scripts(filename)
    files.each do |file|
      SCRIPT_ISEQS__[file].each do |iseq|
        found_iseq = find_iseq_with_line_from_iseq(iseq, lineno, true)
        return found_iseq if found_iseq
      end
    end
    return nil
  end
end
# Demo it
if __FILE__ == $0
  include Trepanning
  if !(ARGV.size == 1 && ARGV[0] == 'noload')
    ISEQS__        = {}
    SCRIPT_ISEQS__ = {}
    ARGV[0..-1]    = ['noload']
    load(__FILE__)
  else    
    load 'tmpdir.rb'
    tmpdir_dir = File.dirname(find_scripts('tmpdir.rb')[0])
    p tmpdir_dir
    %w(tmpdir.rb /tmpdir.rb sometmpdir.rb).each do |filename|
      p find_scripts(filename)
    end
    p find_scripts(__FILE__)
    def tmpdir
      'to conflict with the other tmpdir'
    end
    p find_iseqs(ISEQS__, "tmpdir@#{__FILE__}")
    puts '-' * 20
    p SCRIPT_ISEQS__.keys
    puts '-' * 20
    scripts, rejected = filter_scripts(tmpdir_dir)
    p scripts.keys
    p rejected.keys
    puts '-' * 20
    p SCRIPT_ISEQS__.keys
    # require_relative '../lib/trepanning'; debugger
    p find_iseqs_with_lineno(__FILE__, __LINE__)
  end
end
