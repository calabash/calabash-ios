#!/usr/bin/env ruby

def log_cmd(msg)
  puts "\033[36mEXEC: #{msg}\033[0m" if msg
end


def log_pass(msg)
  puts "\033[32mPASS: #{msg}\033[0m" if msg
end

def log_fail(msg)
  puts "\033[31mFAIL: #{msg}\033[0m" if msg
end

def do_system(cmd, opts={})
  default_opts = {:pass_msg => nil,
                  :fail_msg => nil,
                  :exit_on_nonzero_status => true,
                  :env_vars => {},
                  :log_cmd => true}
  merged_opts = default_opts.merge(opts)

  log_cmd cmd if merged_opts[:log_cmd]

  exit_on_err = merged_opts[:exit_on_nonzero_status]
  unless exit_on_err
    system 'set +e'
  end

  env_vars = merged_opts[:env_vars]
  res = system(env_vars, cmd)
  exit_code = $?.exitstatus

  if res
    log_pass merged_opts[:pass_msg]
  else
    log_fail merged_opts[:fail_msg]
    exit exit_code if exit_on_err
  end
  system 'set -e'
  exit_code
end

def travis_ci?
  ENV['TRAVIS'] != '' or ENV['TRAVIS'] != '0' or ENV['TRAVIS'] != 0
end

def update_rubygems
  do_system('gem update --system',
            {:pass_msg => 'updated rubygems',
             :fail_msg => 'could not update rubygems'})
end

def uninstall_gem(gem_name)
  do_system("gem uninstall -Vax --force --no-abort-on-dependent #{gem_name}",
            {:pass_msg => "uninstalled '#{gem_name}'",
             :fail_msg => "could not uninstall '#{gem_name}'"})
end

def install_bundler
  do_system('gem install --no-document bundler',
            {:pass_msg => 'installed bundler',
             :fail_msg => 'could not install bundler'})
end

def install_calabash_cucumber(opts={})
  default_opts = {:prerelease => true}
  merged_opts = default_opts.merge(opts)
  pre = merged_opts[:prerelease] ? '--pre' : ''
  do_system("gem install --no-document calabash-cucumber #{pre}",
            {:pass_msg => 'install calabash-cucumber',
             :fail_msg => 'could not install calabash-cucumber'})
end


