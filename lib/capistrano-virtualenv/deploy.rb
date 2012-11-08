
require 'uri'

module Capistrano
  module Virtualenv
    def self.extended(configuration)
      configuration.load {
        namespace(:virtualenv) {
          _cset(:virtualenv_use_system, false) # controls whether virtualenv should be use system packages or not.

          _cset(:virtualenv_script_url, 'https://raw.github.com/pypa/virtualenv/master/virtualenv.py')
          _cset(:virtualenv_script_file) {
            File.join(shared_path, 'virtualenv', File.basename(URI.parse(virtualenv_script_url).path))
          }
          _cset(:virtualenv_bootstrap_python, 'python') # the python executable which will be used to craete virtualenv
          _cset(:virtualenv_cmd) {
            [
              virtualenv_bootstrap_python,
              virtualenv_script_file,
              virtualenv_options,
            ].flatten.join(' ')
          }
          _cset(:virtualenv_options) {
            os = %w(--quiet)
            os << "--system-site-packages" if virtualenv_use_system
            os
          }
          _cset(:virtualenv_easy_install_options, %w(--quiet))
          _cset(:virtualenv_pip_options, %w(--quiet))
          _cset(:virtualenv_pip_install_options, [])
          _cset(:virtualenv_pip_package, 'pip')
          _cset(:virtualenv_requirements, []) # primary package list
          _cset(:virtualenv_requirements_file) { # secondary package list
            File.join(release_path, 'requirements.txt')
          }
          _cset(:virtualenv_build_requirements, {})
          _cset(:virtualenv_install_packages, []) # apt packages

          ## shared virtualenv:
          ## - created in shared_path
          ## - to be used to share libs between releases
          _cset(:virtualenv_shared_path) {
            File.join(shared_path, 'virtualenv', 'shared')
          }
          _cset(:virtualenv_shared_python) {
            File.join(virtualenv_shared_path, 'bin', 'python')
          }
          _cset(:virtualenv_shared_easy_install) {
            File.join(virtualenv_shared_path, 'bin', 'easy_install')
          }
          _cset(:virtualenv_shared_easy_install_cmd) {
            # execute from :virtualenv_shared_python
            # since `virtualenv --relocatable` will not set shebang line with absolute path.
            [
              virtualenv_shared_python,
              virtualenv_shared_easy_install,
              virtualenv_easy_install_options,
            ].flatten.join(' ')
          }
          _cset(:virtualenv_shared_pip) {
            File.join(virtualenv_shared_path, 'bin', 'pip')
          }
          _cset(:virtualenv_shared_pip_cmd) {
            [
              virtualenv_shared_python,
              virtualenv_shared_pip,
              virtualenv_pip_options,
            ].flatten.join(' ')
          }

          ## release virtualenv
          ## - created in release_path
          ## - common libs are copied from shared virtualenv
          ## - will be used for running application
          _cset(:virtualenv_release_path) { # the path where runtime virtualenv will be created
            File.join(release_path, 'vendor', 'virtualenv')
          }
          _cset(:virtualenv_release_python) { # the python executable within virtualenv
            File.join(virtualenv_release_path, 'bin', 'python')
          }
          _cset(:virtualenv_release_easy_install) {
            File.join(virtualenv_release_path, 'bin', 'easy_install')
          }
          _cset(:virtualenv_release_easy_install_cmd) {
            [
              virtualenv_release_python,
              virtualenv_release_easy_install,
              virtualenv_easy_install_options,
            ].flatten.join(' ')
          }
          _cset(:virtualenv_release_pip) {
            File.join(virtualenv_release_path, 'bin', 'pip')
          }
          _cset(:virtualenv_release_pip_cmd) {
            [
              virtualenv_release_python,
              virtualenv_release_pip,
              virtualenv_pip_options,
            ].flatten.join(' ')
          }

          ## current virtualenv
          ## - placed in current_path
          ## - virtualenv of currently running application
          _cset(:virtualenv_current_path) {
            File.join(current_path, 'vendor', 'virtualenv')
          }
          _cset(:virtualenv_current_python) {
            File.join(virtualenv_current_path, 'bin', 'python')
          }
          _cset(:virtualenv_current_easy_install) {
            File.join(virtualenv_current_path, 'bin', 'easy_install')
          }
          _cset(:virtualenv_current_easy_install_cmd) {
            [
              virtualenv_current_python,
              virtualenv_current_easy_install,
              virtualenv_easy_install_options,
            ].flatten.join(' ')
          }
          _cset(:virtualenv_current_pip) {
            File.join(virtualenv_current_path, 'bin', 'pip')
          }
          _cset(:virtualenv_current_pip_cmd) {
            [
              virtualenv_current_python,
              virtualenv_current_pip,
              virtualenv_pip_options,
            ].flatten.join(' ')
          }

          desc("Setup virtualenv.")
          task(:setup, :except => { :no_release => true }) {
            transaction {
              install
              create_shared
            }
          }
          after 'deploy:setup', 'virtualenv:setup'

          desc("Install virtualenv.")
          task(:install, :except => { :no_release => true }) {
            run("#{sudo} apt-get install #{virtualenv_install_packages.join(' ')}") unless virtualenv_install_packages.empty?
            dirs = [ File.dirname(virtualenv_script_file) ].uniq()
            run("mkdir -p #{dirs.join(' ')} && ( test -f #{virtualenv_script_file} || wget --no-verbose -O #{virtualenv_script_file} #{virtualenv_script_url} )")
          }

          desc("Uninstall virtualenv.")
          task(:uninstall, :except => { :no_release => true }) {
            run("rm -f #{virtualenv_script_file}")
          }

          task(:create_shared, :except => { :no_release => true }) {
            dirs = [ File.dirname(virtualenv_shared_path) ].uniq()
            cmds = [ ]
            cmds << "mkdir -p #{dirs.join(' ')}"
            cmds << "( test -d #{virtualenv_shared_path} || #{virtualenv_cmd} #{virtualenv_shared_path} )"
            cmds << "( test -x #{virtualenv_shared_pip} || #{virtualenv_shared_easy_install_cmd} #{virtualenv_pip_package} )"
            cmds << "#{virtualenv_shared_python} --version && #{virtualenv_shared_pip_cmd} --version"
            run(cmds.join(' && '))
          }

          task(:destroy_shared, :except => { :no_release => true }) {
            run("rm -rf #{virtualenv_shared_path}")
          }

          desc("Update virtualenv for project.")
          task(:update, :except => { :no_release => true }) {
            transaction {
              update_shared
              create_release
            }
          }
          after 'deploy:finalize_update', 'virtualenv:update'

          task(:update_shared, :except => { :no_release => true }) {
            unless virtualenv_requirements.empty?
              tempfile = "/tmp/requirements.txt.#{$$}"
              begin
                top.put(virtualenv_requirements.join("\n"), tempfile)
                run("diff -u #{virtualenv_requirements_file} #{tempfile} || mv -f #{tempfile} #{virtualenv_requirements_file}")
              ensure
                run("rm -f #{tempfile}")
              end
            end
            run("touch #{virtualenv_requirements_file} && #{virtualenv_shared_pip_cmd} install #{virtualenv_pip_install_options.join(' ')} -r #{virtualenv_requirements_file}")

            execute = virtualenv_build_requirements.map { |package, options|
              build_options = ( options || [] )
              execute << "#{virtualenv_shared_pip_cmd} install #{virtualenv_pip_install_options.join(' ')} #{build_options.join(' ')} #{package.dump}"
            }
            run(execute.join(' && ')) unless execute.empty?
          }

          task(:create_release, :except => { :no_release => true }) {
            dirs = [ File.dirname(virtualenv_release_path) ].uniq()
            cmds = [ ]
            cmds << "mkdir -p #{dirs.join(' ')}"
            # TODO: turn :virtualenv_use_relocatable true if it will be an official features.
            # `virtualenv --relocatable` does not work expectedly as of virtualenv 1.7.2.
            if fetch(:virtualenv_use_relocatable, false)
              cmds << "#{virtualenv_cmd} --relocatable #{virtualenv_shared_path}"
              cmds << "cp -RPp #{virtualenv_shared_path} #{virtualenv_release_path}"
            else
              cmds << "( test -d #{virtualenv_release_path} || #{virtualenv_cmd} #{virtualenv_release_path} )"
              cmds << "( test -x #{virtualenv_release_pip} || #{virtualenv_release_easy_install_cmd} #{virtualenv_pip_package} )"
              cmds << "#{virtualenv_release_python} --version && #{virtualenv_release_pip_cmd} --version"
              cmds << "rsync -lrpt -u #{virtualenv_shared_path}/bin/ #{virtualenv_release_path}/bin/" # copy binaries and scripts from shared virtualenv
              cmds << "sed -i -e 's|^#!#{virtualenv_shared_path}/bin/python.*$|#!#{virtualenv_release_path}/bin/python|' #{virtualenv_release_path}/bin/*"
              cmds << "rsync -lrpt #{virtualenv_shared_path}/lib/ #{virtualenv_release_path}/lib/" # copy libraries from shared virtualenv
            end
            run(cmds.join(' && '))
          }
        }
      }
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::Virtualenv)
end

# vim:set ft=ruby :
