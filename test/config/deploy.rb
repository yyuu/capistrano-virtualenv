set :application, "capistrano-virtualenv"
set :repository, "."
set :deploy_to do
  File.join("/home", user, application)
end
set :deploy_via, :copy
set :scm, :none
set :use_sudo, false
set :user, "vagrant"
set :password, "vagrant"
set :ssh_options, {
  :auth_methods => %w(publickey password),
  :keys => File.join(ENV["HOME"], ".vagrant.d", "insecure_private_key"),
  :user_known_hosts_file => "/dev/null"
}

## pyenv ##
require "capistrano-pyenv"
set(:pyenv_python_version, "2.7.3")

role :web, "192.168.33.10"
role :app, "192.168.33.10"
role :db,  "192.168.33.10", :primary => true

$LOAD_PATH.push(File.expand_path("../../lib", File.dirname(__FILE__)))
require "capistrano-virtualenv"

def _invoke_command(cmdline, options={})
  if options[:via] == :run_locally
    run_locally(cmdline)
  else
    invoke_command(cmdline, options)
  end
end

def assert_file_exists(file, options={})
  begin
    _invoke_command("test -f #{file.dump}", options)
  rescue
    logger.debug("assert_file_exists(#{file}) failed.")
    _invoke_command("ls #{File.dirname(file).dump}", options)
    raise
  end
end

def assert_file_not_exists(file, options={})
  begin
    _invoke_command("test \! -f #{file.dump}", options)
  rescue
    logger.debug("assert_file_not_exists(#{file}) failed.")
    _invoke_command("ls #{File.dirname(file).dump}", options)
    raise
  end
end

def assert_command(cmdline, options={})
  begin
    _invoke_command(cmdline, options)
  rescue
    logger.debug("assert_command(#{cmdline}) failed.")
    raise
  end
end

def assert_command_fails(cmdline, options={})
  failed = false
  begin
    _invoke_command(cmdline, options)
  rescue
    logger.debug("assert_command_fails(#{cmdline}) failed.")
    failed = true
  ensure
    abort unless failed
  end
end

def reset_virtualenv!
  variables.each_key do |key|
    reset!(key) if /^virtualenv_/ =~ key
  end
end

def uninstall_virtualenv!
  run("rm -rf #{virtualenv_shared_path.dump}")
  run("rm -rf #{virtualenv_release_path.dump}")
end

task(:test_all) {
  find_and_execute_task("test_default")
}

on(:load) {
  run("rm -rf #{deploy_to.dump}")
}

namespace(:test_default) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_default", "test_default:setup"
  after "test_default", "test_default:teardown"

  task(:setup) {
    uninstall_virtualenv!
    set(:virtualenv_requirements, %w(simplejson))
    reset_virtualenv!
    find_and_execute_task("deploy:setup")
  }

  task(:teardown) {
  }

  task(:test_deploy) {
    assert_command("#{virtualenv_shared_python} --version")
    assert_command_fails("echo null | #{virtualenv_shared_python} -m simplejson.tool")
    find_and_execute_task("deploy")
    assert_command("#{virtualenv_release_python} --version")
    assert_command("echo null | #{virtualenv_release_python} -m simplejson.tool")
    assert_command("#{virtualenv_current_python} --version")
    assert_command("echo null | #{virtualenv_current_python} -m simplejson.tool")
  }

  task(:test_redeploy) {
    assert_command("#{virtualenv_shared_python} --version")
    assert_command("echo null | #{virtualenv_shared_python} -m simplejson.tool")
    variables.each_key do |key|
      reset!(key)
    end
    find_and_execute_task("deploy")
    assert_command("#{virtualenv_release_python} --version")
    assert_command("echo null | #{virtualenv_release_python} -m simplejson.tool")
    assert_command("#{virtualenv_current_python} --version")
    assert_command("echo null | #{virtualenv_current_python} -m simplejson.tool")
  }

  task(:test_rollback) {
    assert_command("#{virtualenv_shared_python} --version")
    assert_command("echo null | #{virtualenv_shared_python} -m simplejson.tool")
    variables.each_key do |key|
      reset!(key)
    end
    find_and_execute_task("deploy:rollback")
    assert_command_fails("#{virtualenv_release_python} --version")
    assert_command_fails("echo null | #{virtualenv_release_python} -m simplejson.tool")
    assert_command("#{virtualenv_current_python} --version")
    assert_command("echo null | #{virtualenv_current_python} -m simplejson.tool")
  }

  task(:test_virtualenv_exec) {
    virtualenv.exec("python --version", :virtualenv => virtualenv_shared_path)
    virtualenv.exec("python --version", :virtualenv => virtualenv_current_path)
  }
}

# vim:set ft=ruby sw=2 ts=2 :
