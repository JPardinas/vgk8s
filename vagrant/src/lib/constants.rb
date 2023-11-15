module CONSTANTS
  BOOT_TIMEOUT = 600
  DEFAULT_MASTER_BOX_IMAGE_NAME = "bento/ubuntu-22.04"
  DEFAULT_MASTER_BOX_IMAGE_VERSION = "202309.08.0"
  DEFAULT_MASTER_CPUS = 4
  DEFAULT_MASTER_DISK_SIZE = "40GB"
  DEFAULT_MASTER_MEMORY = 8192
  DEFAULT_MASTER_SUBNET = "192.168.56"
  ENV_FILE = File.expand_path("../../../.env", __FILE__)
  IS_DEBUG = ARGV.include?('--debug')
  IS_UP = ARGV.include?('up')
  PROVIDER_DEFAULT = "virtualbox"
  REQUIRED_ENVIRONMENT_VARIABLES = JSON.parse(File.read(File.expand_path("../../config/requirements.json", __FILE__)))["environment-variables"]
  REQUIRED_PLUGINS = JSON.parse(File.read(File.expand_path("../../config/requirements.json", __FILE__)))["vagrant-plugins"]
  VALID_BOXES = JSON.parse(File.read(File.expand_path("../../config/valid-boxes.json", __FILE__)))
  VALID_PROVIDERS = JSON.parse(File.read(File.expand_path("../../config/requirements.json", __FILE__)))["providers"]
  VERSION = "0.0.1"
  VM_CONTROL_SERVER_NAME = "vgk8s-master"
  VM_SYNCED_FOLDER_WORKING_DIRECTORY = "/home/vagrant/working_directory"
  VM_SYNCED_FOLDER_VAGRANT = "/vagrant"
end