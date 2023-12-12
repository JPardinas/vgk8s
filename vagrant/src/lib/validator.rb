require_relative 'constants'


module Validator
  def self.check_if_box_is_supported()
    $logger.info(self, "Checking if the box #{CONSTANTS::VAGRANT_BOX_NAME}:#{CONSTANTS::VAGRANT_BOX_VERSION} is supported")
    unless CONSTANTS::VAGRANT_BOX_NAME.include?("/")
      $logger.log_error_and_raise_exception(self, "Box #{CONSTANTS::VAGRANT_BOX_NAME} is not supported. Please use one of the following boxes: #{CONSTANTS::CONFIG_VALID_BOXES.keys}")
    end

    provider = CONSTANTS::VAGRANT_BOX_NAME.split("/")[0]
    box = CONSTANTS::VAGRANT_BOX_NAME.split("/")[1]
    $logger.key_value(self, "vm_box_provider", provider, Logger::DEBUG)
    $logger.key_value(self, "vm_box", box, Logger::DEBUG)
    $logger.key_value(self, "vm_version", CONSTANTS::VAGRANT_BOX_VERSION, Logger::DEBUG)

    $logger.key_value(self, "Valid boxes:", CONSTANTS::CONFIG_VALID_BOXES, Logger::DEBUG)

    unless CONSTANTS::CONFIG_VALID_BOXES[provider]
      $logger.log_error_and_raise_exception(self, "Provider #{provider} is not supported. Please use one of the following providers: #{CONSTANTS::CONFIG_VALID_BOXES.keys}")
    end

    unless CONSTANTS::CONFIG_VALID_BOXES[provider][box]
      $logger.log_error_and_raise_exception(self, "Box #{box} is not supported. Please use one of the following boxes: #{CONSTANTS::CONFIG_VALID_BOXES[provider].keys}")
    end

    unless CONSTANTS::CONFIG_VALID_BOXES[provider][box].include?(CONSTANTS::VAGRANT_BOX_VERSION)
      $logger.log_error_and_raise_exception(self, "Box #{box}:#{CONSTANTS::VAGRANT_BOX_VERSION} is not supported. Please use one of the following versions: #{CONSTANTS::CONFIG_VALID_BOXES[provider][box]}")
    end

    $logger.success(self, "Box is supported.")
  end

  def self.check_if_provider_is_supported()
    $logger.info(self, "Checking if the provider is supported...")
    provider_name = Utils.get_provider_name()
    $logger.key_value(self, "Provider", provider_name, Logger::DEBUG)
    unless CONSTANTS::CONFIG_VALID_PROVIDERS.include?(provider_name)
      $logger.log_error_and_raise_exception(self, "Provider #{provider_name} is not supported. Please use one of the following providers: #{CONSTANTS::CONFIG_VALID_PROVIDERS}")
    end
    $logger.success(self, "Provider is supported.")
  end

  def self._get_not_installed_plugins_list(plugins)
    not_installed_plugins = []
    # plugins is a map of key-value pairs, value are the versions in an array
    plugins.each do |plugin, versions|
      unless Vagrant.has_plugin?(plugin)
        version = versions[0]
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
    if CONSTANTS::VAGRANT_IS_WINDOWS_WSL
      not_installed_plugins_windows = _get_not_installed_plugins_list(CONSTANTS::REQUIRED_PLUGINS_WINDOWS)
      not_installed_plugins = not_installed_plugins + not_installed_plugins_windows
    end

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

  def self.validate_windows_wsl()
    if CONSTANTS::VAGRANT_IS_WINDOWS_WSL
      $logger.info(self, "Detected Windows WSL.")
      $logger.info(self, "Checking if /etc/vbox/networks.conf contains 10.0.0.0/8")
      file = "/etc/vbox/networks.conf"
      # check if file exists
      unless File.file?(file)
        $logger.log_error_and_raise_exception(self, "File #{file} does not exist. Please create it and add 10.0.0.0/8 to it.")
      end

      if File.readlines("/etc/vbox/networks.conf").any? { |line| line.include?("10.0.0.0/8") }
        $logger.success(self, "10.0.0.0/8 is present in /etc/vbox/networks.conf")
      else
        $logger.log_error_and_raise_exception(self, "Please add 10.0.0.0/8 to /etc/vbox/networks.conf")
      end

      # verify vault_password file has not executable permissions
      file = CONSTANTS::ANSIBLE_FOLDER_HOST + "/.vault_password"
      if File.exist?(file)
        if File.executable?(file)
          $logger.log_error_and_raise_exception(self, "File #{file} has executable permissions. Please remove them. e.g. chmod 600 #{file}")
        else
          $logger.success(self, "File #{file} does not have executable permissions.")
        end
      else
        $logger.log_error_and_raise_exception(self, "File #{file} does not exist. Please create it.")
      end

    end
  end
  
end