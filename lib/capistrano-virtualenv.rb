require "capistrano-virtualenv/version"
require "capistrano/configuration/resources/platform_resources"
require "uri"

module Capistrano
  module Virtualenv
    def self.extended(configuration)
      configuration.load {
        namespace(:virtualenv) {
          _cset(:virtualenv_use_system, false) # controls whether virtualenv should be use system packages or not.
          _cset(:virtualenv_script_url, "https://raw.github.com/pypa/virtualenv/1.9.1/virtualenv.py")
          _cset(:virtualenv_script_file) { File.join(shared_path, "virtualenv", File.basename(URI.parse(virtualenv_script_url).path)) }
          _cset(:virtualenv_bootstrap_python, "python") # the python executable which will be used to craete virtualenv
          _cset(:virtualenv_cmd) { command }
          _cset(:virtualenv_default_options) {
            options = %w(--distribute --quiet)
            options << "--system-site-packages" if virtualenv_use_system
            options
          }
          _cset(:virtualenv_options) { virtualenv_default_options + fetch(:virtualenv_extra_options, []) }
          _cset(:virtualenv_easy_install_options) { # TODO: remove this
            logger.info(":virtualenv_easy_install_options has been deprecated.")
            %w(--quiet)
          }
          _cset(:virtualenv_pip_default_options, %w(--quiet))
          _cset(:virtualenv_pip_options) { virtualenv_pip_default_options + fetch(:virtualenv_pip_extra_options, []) }
          _cset(:virtualenv_pip_install_options, [])
          _cset(:virtualenv_requirements, []) # primary package list
          _cset(:virtualenv_requirements_file) { File.join(release_path, "requirements.txt") } # secondary package list
          _cset(:virtualenv_build_requirements, {})

          ## shared virtualenv:
          ## - created in shared_path
          ## - to be used to share libs between releases
          _cset(:virtualenv_shared_path) { File.join(shared_path, "virtualenv", "shared") }
          _cset(:virtualenv_shared_bin_path) { File.join(virtualenv_shared_path, "bin") }
          _cset(:virtualenv_shared_python) { File.join(virtualenv_shared_bin_path, "python") }
          _cset(:virtualenv_shared_easy_install) { # TODO: remove this
            logger.info(":virtualenv_shared_easy_install has been deprecated.")
            File.join(virtualenv_shared_bin_path, "easy_install")
          }
          _cset(:virtualenv_shared_easy_install_cmd) { # TODO: remove this
            # execute from :virtualenv_shared_python
            # since `virtualenv --relocatable` will not set shebang line with absolute path.
            logger.info(":virtualenv_shared_easy_install_cmd has been deprecated.")
            [
              virtualenv_shared_python.dump,
              virtualenv_shared_easy_install.dump,
              virtualenv_easy_install_options.map { |x| x.dump }.join(" "),
            ].join(" ")
          }
          # execute from :virtualenv_shared_python
          # since `virtualenv --relocatable` will not set shebang line with absolute path.
          _cset(:virtualenv_shared_pip) { # TODO: remove this
            logger.info(":virtualenv_shared_pip has been deprecated.")
            File.join(virtualenv_shared_bin_path, "pip")
          }
          _cset(:virtualenv_shared_pip_cmd) { # TODO: remove this
            logger.info(":virtualenv_shared_pip_cmd has been deprecated.")
            [
              virtualenv_shared_python.dump,
              virtualenv_shared_pip.dump,
              virtualenv_pip_options.map { |x| x.dump }.join(" "),
            ].join(" ")
          }

          ## release virtualenv
          ## - created in release_path
          ## - common libs are copied from shared virtualenv
          ## - will be used for running application
          _cset(:virtualenv_release_path) { File.join(release_path, "vendor", "virtualenv") } # the path where runtime virtualenv will be created
          _cset(:virtualenv_release_bin_path) { File.join(virtualenv_release_path, "bin") }
          _cset(:virtualenv_release_python) { File.join(virtualenv_release_bin_path, "python") } # the python executable within virtualenv
          _cset(:virtualenv_release_easy_install) { # TODO: remove this
            logger.info(":virtualenv_release_easy_install has been deprecated.")
            File.join(virtualenv_release_bin_path, "easy_install")
          }
          _cset(:virtualenv_release_easy_install_cmd) { # TODO: remove this
            # execute from :virtualenv_release_python
            # since `virtualenv --relocatable` will not set shebang line with absolute path.
            logger.info(":virtualenv_release_easy_install_cmd has been deprecated.")
            [
              virtualenv_release_python.dump,
              virtualenv_release_easy_install.dump,
              virtualenv_easy_install_options.map { |x| x.dump }.join(" "),
            ].join(" ")
          }
          _cset(:virtualenv_release_pip) { # TODO: remove this
            logger.info(":virtualenv_release_pip has been deprecated.")
            File.join(virtualenv_release_bin_path, "pip")
          }
          _cset(:virtualenv_release_pip_cmd) { # TODO: remove this
            logger.info(":virtualenv_release_pip_cmd has been deprecated.")
            [
              virtualenv_release_python.dump,
              virtualenv_release_pip.dump,
              virtualenv_pip_options.map { |x| x.dump }.join(" "),
            ].flatten.join(" ")
          }

          ## current virtualenv
          ## - placed in current_path
          ## - virtualenv of currently running application
          _cset(:virtualenv_current_path) { File.join(current_path, "vendor", "virtualenv") }
          _cset(:virtualenv_current_bin_path) { File.join(virtualenv_current_path, "bin") }
          _cset(:virtualenv_current_python) { File.join(virtualenv_current_bin_path, "python") }
          _cset(:virtualenv_current_easy_install) { # TODO: remove this
            logger.info(":virtualenv_current_easy_install has been deprecated.")
            File.join(virtualenv_current_bin_path, "easy_install")
          }
          _cset(:virtualenv_current_easy_install_cmd) { # TODO: remove this
            # execute from :virtualenv_current_python
            # since `virtualenv --relocatable` will not set shebang line with absolute path.
            logger.info(":virtualenv_current_easy_install_cmd has been deprecated.")
            [
              virtualenv_current_python.dump,
              virtualenv_current_easy_install.dump,
              virtualenv_easy_install_options.map { |x| x.dump }.join(" "),
            ].join(" ")
          }
          _cset(:virtualenv_current_pip) {
            logger.info(":virtualenv_current_pip has been deprecated.")
            File.join(virtualenv_current_path, "bin", "pip")
          }
          _cset(:virtualenv_current_pip_cmd) {
            logger.info(":virtualenv_current_pip_cmd has been deprecated.")
            [
              virtualenv_current_python.dump,
              virtualenv_current_pip.dump,
              virtualenv_pip_options.map { |x| x.dump }.join(" "),
            ].flatten.join(" ")
          }

          desc("Setup virtualenv.")
          task(:setup, :except => { :no_release => true }) {
            transaction {
              dependencies if fetch(:virtualenv_setup_dependencies, true)
              install
              create_shared
            }
          }
          after "deploy:setup", "virtualenv:setup"

          desc("Install virtualenv.")
          task(:install, :except => { :no_release => true }) {
            run("mkdir -p #{File.dirname(virtualenv_script_file).dump}")
            run("test -f #{virtualenv_script_file.dump} || wget --no-verbose -O #{virtualenv_script_file.dump} #{virtualenv_script_url.dump}")
          }

          _cset(:virtualenv_install_packages, %w(python rsync))
          task(:dependencies, :except => { :no_release => true }) {
            platform.packages.install(virtualenv_install_packages)
          }

          desc("Uninstall virtualenv.")
          task(:uninstall, :except => { :no_release => true }) {
            run("rm -f #{virtualenv_script_file.dump}")
          }

          def command(options={})
            [
              virtualenv_bootstrap_python,
              virtualenv_script_file.dump,
              virtualenv_options.map { |x| x.dump }.join(" "),
            ].join(" ")
          end

          def create(destination, options={})
            execute = []
            execute << "mkdir -p #{File.dirname(destination).dump}"
            execute << "( test -d #{destination.dump} || #{command(options)} #{destination.dump} )"
            invoke_command(execute.join(" && "), options)
          end

          def destroy(destination, options={})
            invoke_command("rm -rf #{destination.dump}", options)
          end

          desc("Create shared virtualenv.")
          task(:create_shared, :except => { :no_release => true }) {
            virtualenv.create(virtualenv_shared_path)
          }

          desc("Destroy shared virtualenv.")
          task(:destroy_shared, :except => { :no_release => true }) {
            virtualenv.destroy(virtualenv_shared_path)
          }

          desc("Update virtualenv for project.")
          task(:update, :except => { :no_release => true }) {
            transaction {
              update_shared
              create_release
            }
          }
          after "deploy:finalize_update", "virtualenv:update"

          task(:update_shared, :except => { :no_release => true }) {
            top.put(virtualenv_requirements.join("\n"), virtualenv_requirements_file) unless virtualenv_requirements.empty?
            run("touch #{virtualenv_requirements_file.dump}")
            pip_options = ( virtualenv_pip_options + virtualenv_pip_install_options ).map { |x| x.dump }.join(" ")
            virtualenv.exec("pip install #{pip_options} -r #{virtualenv_requirements_file.dump}",
                            :virtualenv => virtualenv_shared_path)
            virtualenv_build_requirements.each do |package, options|
              options ||= []
              virtualenv.exec("pip install #{pip_options} #{options.map { |x| x.dump }.join(" ")} #{package.dump}",
                             :virtualenv => virtualenv_shared_path)
            end
          }

          def relocate(source, destination, options={})
            execute = []
            execute << "mkdir -p #{File.dirname(destination).dump}"
            # TODO: turn :virtualenv_use_relocatable true if it will be an official features.
            # `virtualenv --relocatable` does not work expectedly as of virtualenv 1.7.2.
            if fetch(:virtualenv_use_relocatable, false)
              execute << %{#{command(options)} --relocatable #{source.dump}}
              execute << %{cp -RPp #{source.dump} #{destination.dump}}
            else
              execute << %{( test -d #{destination.dump} || #{command(options)} #{destination.dump} )}
              # copy binaries and scripts from shared virtualenv
              execute << %{rsync -lrpt #{File.join(source, "bin/").dump} #{File.join(destination, "bin/").dump}}
              execute << %{sed -i -e 's|^#!#{source}/bin/python.*$|#!#{destination}/bin/python|' #{destination}/bin/*}
              # copy libraries from shared virtualenv
              execute << %{rsync -lrpt #{File.join(source, "lib/").dump} #{File.join(destination, "lib/").dump}}
            end
            invoke_command(execute.join(" && "), options)
          end

          task(:create_release, :except => { :no_release => true }) {
            virtualenv.relocate(virtualenv_shared_path, virtualenv_release_path)
          }

          def exec(cmdline, options={})
            options = options.dup
            virtualenv = ( options.delete(:virtualenv) || virtualenv_shared_path )
            options[:env] = options.fetch(:env, {}).merge("PATH" => [ File.join(virtualenv, "bin"), "$PATH" ].join(":"))
            invoke_command(cmdline, options)
          end
        }
      }
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::Virtualenv)
end

# vim:set ft=ruby :
