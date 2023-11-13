module CONSTANTS
  BOOT_TIMEOUT = 600
  ENV_FILE = File.expand_path("../../../.env", __FILE__)
  IS_DEBUG = ARGV.include?('--debug')
  IS_UP = ARGV.include?('up')
  PROVIDER_DEFAULT = "virtualbox"
  REQUIRED_ENVIRONMENT_VARIABLES = JSON.parse(File.read(File.expand_path("../../config/requirements.json", __FILE__)))["environment-variables"]
  REQUIRED_PLUGINS = JSON.parse(File.read(File.expand_path("../../config/requirements.json", __FILE__)))["vagrant-plugins"]
  VALID_BOXES = JSON.parse(File.read(File.expand_path("../../config/valid-boxes.json", __FILE__)))
  VERSION = "0.0.1"
  VM_CONTROL_SERVER_NAME = "vgk8s-master"
end