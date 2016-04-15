require 'rubygems'
require 'irb/completion'
require 'irb/ext/save-history'

begin
  require 'awesome_print'
rescue LoadError => e
  msg = ["Caught a LoadError: could not load 'awesome_print'",
         "#{e}",
         '',
         'Use bundler (recommended) or uninstall awesome_print.',
         '',
         '# Use bundler (recommended)',
         '$ bundle update',
         '$ bundle exec calabash-ios console',
         '',
         '# Uninstall',
         '$ gem update --system',
         '$ gem uninstall -Vax --force --no-abort-on-dependent awesome_print']
  puts msg
  exit(1)
end

AwesomePrint.irb!

ARGV.concat [ '--readline',
              '--prompt-mode',
              'simple']

IRB.conf[:SAVE_HISTORY] = 50
IRB.conf[:HISTORY_FILE] = '.irb-history'

require 'calabash-cucumber/operations'

extend Calabash::Cucumber::Operations

def embed(x,y=nil,z=nil)
  puts "Screenshot at #{x}"
end

require "calabash-cucumber"

def preferences
  Calabash::Cucumber::Preferences.new
end

def disable_usage_tracking
  preferences.usage_tracking = "none"
  puts "Calabash will not collect usage information."
  "none"
end

def enable_usage_tracking(level="system_info")
  preferences.usage_tracking = level
  puts "Calabash will collect statistics using the '#{level}' rule."
  level
end

@ai=:accessibilityIdentifier
@al=:accessibilityLabel

def print_marks(marks, max_width)
  counter = -1
  marks.sort.each { |elm|
    printf("%4s %#{max_width + 2}s => %s\n", "[#{counter = counter + 1}]", elm[0], elm[1])
  }
end

def accessibility_marks(kind, opts={})
  opts = {:print => true, :return => false}.merge(opts)

  kinds = [:id, :label]
  raise "'#{kind}' is not one of '#{kinds}'" unless kinds.include?(kind)

  res = Array.new
  max_width = 0
  query('*').each { |view|
    aid = view[kind.to_s]
    unless aid.nil? or aid.eql?('')
      cls = view['class']
      len = cls.length
      max_width = len if len > max_width
      res << [cls, aid]
    end
  }
  print_marks(res, max_width) if opts[:print]
  opts[:return] ? res : nil
end

def text_marks(opts={})
  opts = {:print => true, :return => false}.merge(opts)

  indexes = Array.new
  idx = 0
  all_texts = query('*', :text)
  all_texts.each { |view|
    indexes << idx unless view.eql?('*****') or view.eql?('')
    idx = idx + 1
  }

  res = Array.new

  all_views = query('*')
  max_width = 0
  indexes.each { |index|
    view = all_views[index]
    cls = view['class']
    text = all_texts[index]
    len = cls.length
    max_width = len if len > max_width
    res << [cls, text]
  }

  print_marks(res, max_width) if opts[:print]
  opts[:return] ? res : nil
end

def ids
  accessibility_marks(:id)
end

def labels
  accessibility_marks(:label)
end

def text
  text_marks
end

def marks
  opts = {:print => false, :return => true }
  res = accessibility_marks(:id, opts).each { |elm|elm << :ai }
  res.concat(accessibility_marks(:label, opts).each { |elm| elm << :al })
  res.concat(text_marks(opts).each { |elm| elm << :text })
  max_width = 0
  res.each { |elm|
    len = elm[0].length
    max_width = len if len > max_width
  }

  counter = -1
  res.sort.each { |elm|
    printf("%4s %-4s => %#{max_width}s => %s\n",
           "[#{counter = counter + 1}]",
           elm[2], elm[0], elm[1])
  }
  nil
end

