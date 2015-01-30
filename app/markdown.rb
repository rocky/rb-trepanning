# -*- coding: utf-8 -*-
# Copyright (C) 2015 Rocky Bernstein <rockyb@rubyforge.net>

begin require 'term/ansicolor'; rescue LoadError; end
require 'redcarpet'
require 'redcarpet/render_strip'

module Redcarpet

    module Render

        class Terminal < StripDown

            attr_accessor :width
            attr_accessor :try_ansi

            def strip_term_sequence(text)
                # to be completed...
                text
            end

            def ansi?
                defined?(Term::ANSIColor) and try_ansi
            end

            def header(title, level)
                if ansi?
                    Term::ANSIColor.bold + title + Term::ANSIColor.reset + "\n"
                else
                    sep = (level == 1) ? '=' : '-'
                    title + "\n" + (sep * title.size) + "\n"
                end
            end

            def codespan(text)
                if ansi?
                    Term::ANSIColor.underline + text + Term::ANSIColor.reset + "\n"
                else
                    "'" + text + "'"
                end
            end
            def triple_emphasis(text)
                if ansi?
                    Term::ANSIColor.bold + text + Term::ANSIColor.reset
                else
                    '***' + text + '***'
                end
            end

            def double_emphasis(text)
                if ansi?
                    Term::ANSIColor.bold + text + Term::ANSIColor.reset
                else
                    '**' + text + '**'
                end
            end

            def emphasis(text)
                if ansi?
                    Term::ANSIColor.italic + text + Term::ANSIColor.reset
                else
                    '*' + text + '*'
                end
            end

            def underline(text)
                if ansi?
                    Term::ANSIColor.italic + text + Term::ANSIColor.reset
                else
                    '_' + text + '_'
                end
            end

            def strikethrough(text)
                if ansi?
                    Term::ANSIColor.striketrhough + text + Term::ANSIColor.reset
                else
                    '_' + text + '_'
                end
            end

            def linebreak
                "\n"
            end

            def paragraph(text)
                lines = []
                line_len = 0
                line = ''
                text.split.each do |word|
                    word_size = strip_term_sequence(word).size
                    if line_len +  word_size > @width
                        lines << line
                        line = word + ' '
                        line_len = word_size
                    else
                        line += word + ' '
                        line_len += word_size + 1
                    end
                end
                lines << line
                lines.join("\n") + "\n\n"
            end

            def list(content, list_type)
                case list_type
                when :ordered
                    @list_count = 0
                    "#{content}\n"
                when :unordered
                    "\n#{content}\n"
                end
            end

            def list_item(content, list_type)
                case list_type
                when :ordered
                    @list_count ||= 0
                    @list_count += 1
                    "#{@list_count}. #{content}"
                when :unordered
                    "* #{content}"
                end
            end
        end
    end
end

class Trepan
    module Markdown
        def render(text, width=80, try_ansi=true)
            @renderer ||= Redcarpet::Render::Terminal.new()
            @renderer.width = width
            @renderer.try_ansi = try_ansi
            @markdown ||= Redcarpet::Markdown.new(@renderer, extensions = {})
            @markdown.render(text)
        end
        module_function :render
    end
end

if __FILE__ == $0
    include Trepan::Markdown
    string = <<EOF
# HI
This is a paragraph

**This** is another *paragraph*.
EOF
    [[80, true],
     [80, false],
     [15, true],
     [15, false]].each do | width, try_ansi|
        puts render(string, width, try_ansi)
        puts '-' * 60
    end
puts
string = <<EOF
If the first non-blank character of a line starts with `#`,
the command is ignored.

* first
* second
* third

1. first
1. second
1. third

## See also
foo
EOF
puts render(string, 50, false)
end
