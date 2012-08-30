# capistrano-virtualenv

a capistrano recipe to deploy python apps with [virtualenv](http://pypi.python.org/pypi/virtualenv).

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-virtualenv'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-virtualenv

## Usage

This recipe will create 2 kind of virtualenv during `deploy` task.

* shared virtualenv
  * created in `shared_path` after `deploy:setup`
  * common libraries are installed here.
* release virtualenv
  * created in `release_path` after `deploy:finalize_update`
  * per-release virtualenv that can be rolled back.

To deploy your application with `virtualenv`, add following in you `config/deploy.rb`.

    # in "config/deploy.rb"
    require 'capistrano-virtualenv'

Following options are available to manage your virtualenv.

 * `:virtualenv_bootstrap_python` - the python executable which will be used to craete virtualenv. by default "python".
 * `:virtualenv_current_path` - virtualenv path under `:current_path`.
 * `:virtualenv_current_python` - python path under `:virtualenv_current_path`.
 * `:virtualenv_easy_install_options` - options for `easy_install`. by defaul "--quiet".
 * `:virtualenv_install_packages` - apt packages dependencies for python.
 * `:virtualenv_pip_options` - options for `pip`. by default "--quiet".
 * `:virtualenv_pip_install_options` - options for `pip install`.
 * `:virtualenv_release_path` - virtualenv path under `:release_path`.
 * `:virtualenv_release_python` - python path under `:virtualenv_release_path`.
 * `:virtualenv_requirements` - the list of `pip` packages should be installed to `virtualenv`.
 * `:virtualenv_requirements_file` - the path to the file that describes library dependencies. by default "requirements.txt".
 * `:virtualenv_script_url` - the download URL of `virtualenv.py`.
 * `:virtualenv_shared_path` - virtualenv path under `:shared_path`.
 * `:virtualenv_shared_python` - python path under `:virtualenv_shared_path`
 * `:virtualenv_use_system` - controls whether virtualenv should be use system packages or not. false by default.
           
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

- YAMASHITA Yuu (https://github.com/yyuu)
- Geisha Tokyo Entertainment Inc. (http://www.geishatokyo.com/)

## License

MIT
