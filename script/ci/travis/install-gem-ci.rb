#!/usr/bin/env ruby
require 'open3'
require File.expand_path(File.join(File.dirname(__FILE__), 'ci-helpers'))

working_directory = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'calabash-cucumber'))

Dir.chdir working_directory do

  do_system('rake install',
            {:pass_msg => 'successfully used rake to install the gem',
             :fail_msg => 'could not install the gem with rake'})

  # Reproduces the dread 'minitest' bug using $ calabash-ios version
  Open3.popen3('calabash-ios version') do  |_, stdout,  stderr, _|
    out = stdout.read.strip
    err = stderr.read.strip

    if err == ''
      out_tokens = out.split(/\s/)
      if out_tokens.count != 1 or not out_tokens.first =~ /(\d+\.\d+\.\d+)(\.pre\d+)?/
        log_fail 'did not report version correctly!'
        log_fail out
        exit 1
      end
    end

    if err != ''
      log_fail 'could not execute `calabash-ios version` without an error'
      log_fail err
      exit 1
    end

    log_pass "successfully reported version as '#{out}'"
    exit 0
  end
end
