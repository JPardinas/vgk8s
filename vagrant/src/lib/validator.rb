require_relative 'constants'


module Validator
  def self.check_if_box_is_supported(box, version)
    $logger.info(self, "Checking if the box #{box}:#{version} is supported")
    unless box.include?("/")
      $logger.log_error_and_raise_exception(self, "Box #{box} is not supported. Please use one of the following boxes: #{CONSTANTS::VALID_BOXES.keys}")
    end

    provider = box.split("/")[0]
    box = box.split("/")[1]
    $logger.key_value(self, "vm_box_provider", provider, Logger::DEBUG)
    $logger.key_value(self, "vm_box", box, Logger::DEBUG)
    $logger.key_value(self, "vm_version", version, Logger::DEBUG)

    $logger.key_value(self, "Valid boxes:", CONSTANTS::VALID_BOXES, Logger::DEBUG)

    unless CONSTANTS::VALID_BOXES[provider]
      $logger.log_error_and_raise_exception(self, "Provider #{provider} is not supported. Please use one of the following providers: #{CONSTANTS::VALID_BOXES.keys}")
    end

    unless CONSTANTS::VALID_BOXES[provider][box]
      $logger.log_error_and_raise_exception(self, "Box #{box} is not supported. Please use one of the following boxes: #{CONSTANTS::VALID_BOXES[provider].keys}")
    end

    unless CONSTANTS::VALID_BOXES[provider][box].include?(version)
      $logger.log_error_and_raise_exception(self, "Box #{box}:#{version} is not supported. Please use one of the following versions: #{CONSTANTS::VALID_BOXES[provider][box]}")
    end

    $logger.success(self, "Box is supported.")
  end

  def self.check_if_provider_is_supported()
    $logger.info(self, "Checking if the provider is supported...")
    provider_name = Utils.get_provider_name()
    $logger.key_value(self, "Provider", provider_name, Logger::DEBUG)
    unless CONSTANTS::VALID_PROVIDERS.include?(provider_name)
      $logger.log_error_and_raise_exception(self, "Provider #{provider_name} is not supported. Please use one of the following providers: #{CONSTANTS::VALID_PROVIDERS}")
    end
    $logger.success(self, "Provider is supported.")
  end

  def self.check_if_required_environment_variables_exist()
    $logger.info(self, "Checking if the required environment variables exist...")
    $logger.key_value(self, "Required environment variables", CONSTANTS::REQUIRED_ENVIRONMENT_VARIABLES, Logger::DEBUG)
    not_defined_env_vars = []
    CONSTANTS::REQUIRED_ENVIRONMENT_VARIABLES.each do |env_var|
        unless ENV[env_var]
            not_defined_env_vars << env_var
        end
    end
    if not_defined_env_vars.length > 0
        $logger.key_value(self, "Following environment variables are not set", not_defined_env_vars, Logger::ERROR)
        $logger.error(self, "Exiting because the required environment variables are not set. Please set them in the .env file or export them in the shell and rerun 'vagrant up'.")
        exit 1
    end
    $logger.success(self, "All required environment variables are set.")
  end

  def self.check_if_work_dir_exists()
    $logger.info(self, "Checking if the work directory exists...")
    $logger.key_value(self, "Work directory", ENV['WORKING_DIRECTORY'], Logger::DEBUG)
    unless File.exist?(File.expand_path("#{ENV['WORKING_DIRECTORY']}"))
      # ask user if they want to create the directory, if yes, create it
      $logger.key_value(self, "Work directory does not exist under #{ENV['WORKING_DIRECTORY']}. Would you like to create it?", "(y/n)", Logger::WARN)
      input = STDIN.gets.chomp
      if input == 'y'
        $logger.info(self, "Creating work directory...")
        Dir.mkdir(File.expand_path("#{ENV['WORKING_DIRECTORY']}"))
      else
        $logger.log_error_and_raise_exception(self, "Exiting because the work directory does not exist. Please create it and rerun 'vagrant up'.")
      end
    end
    $logger.success(self, "Work directory exists.")
  end

  def self._get_not_installed_plugins_list(plugins)
    not_installed_plugins = []
    # plugins is a map of key-value pairs, value are the versions in an array
    plugins.each do |plugin, versions|
      unless Vagrant.has_plugin?(plugin)
        not_installed_plugins << { plugin: plugin, version: version }
      else
        $logger.key_value(self, "Plugin #{plugin} is installed", Vagrant.has_plugin?(plugin), Logger::DEBUG)
      end
      
    end
    not_installed_plugins
  end

  def self.check_required_plugins_are_installed()
    $logger.info(self, "Checking if the required plugins are installed...")
    $logger.key_value(self, "Plugins", CONSTANTS::REQUIRED_PLUGINS, Logger::DEBUG)
    not_installed_plugins = _get_not_installed_plugins_list(CONSTANTS::REQUIRED_PLUGINS)

    if not_installed_plugins.length > 0
        prompt_and_install_missing_plugins(not_installed_plugins)
    else
        $logger.success(self, "All required plugins are installed.")
    end
  end

  def self.prompt_and_install_missing_plugins(not_installed_plugins)
    $logger.error(self, "The following plugins are not installed: #{not_installed_plugins}")
    $logger.key_value(self, "Would you like to install them?", "(y/n)", Logger::WARN)
    input = STDIN.gets.chomp
    if input == 'y'
      $logger.info(self, "Installing plugins...")
      not_installed_plugins.each do |plugin_data|
          plugin = plugin_data[:plugin]
          version = plugin_data[:version]
          $logger.info(self, "Installing #{plugin} version #{version}...")
          system "vagrant plugin install #{plugin} --plugin-version #{version}"
      end
      $logger.success(self, "All required plugins are installed.")
    else
      $logger.log_error_and_raise_exception(self, "Exiting because required plugins are not installed.")
    end
      $logger.log_error_and_raise_exception(self, "Exiting because plugins are not detected until next run. Please run 'vagrant up' again.")
  end
  
end