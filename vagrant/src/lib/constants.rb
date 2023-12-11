require "yaml"


module CONSTANTS
  SETTINGS_FILE = File.expand_path('../../../settings.yml', __FILE__)
  SETTINGS = YAML.load_file SETTINGS_FILE
  ANSIBLE_CORE_VERSION = SETTINGS["ansible"]["version"]
  ANSIBLE_FOLDER_HOST = File.expand_path("../../../../ansible/", __FILE__)
  ANSIBLE_FOLDER_TARGET = SETTINGS["ansible"]["folder_path"]
  
  CHARTS_FOLDER_HOST = File.expand_path("../../../../charts/", __FILE__)
  CHARTS_FOLDER_TARGET = SETTINGS["charts"]["folder_path"]

  CLUSTER_SOFTWARE_CALICO = SETTINGS["cluster"]["software"]["calico"]
  CLUSTER_SOFTWARE_KUBERNETES = SETTINGS["cluster"]["software"]["kubernetes"]
  CLUSTER_SOFTWARE_OS = SETTINGS["cluster"]["software"]["os"]
  CLUSTER_NETWORK_CONTROL_IP = SETTINGS["cluster"]["network"]["control_ip"]
  CLUSTER_NETWORK_DNS_SERVERS = SETTINGS["cluster"]["network"]["dns_servers"]
  CLUSTER_NETWORK_POD_CIDR = SETTINGS["cluster"]["network"]["pod_cidr"]
  CLUSTER_NETWORK_SERVICE_CIDR = SETTINGS["cluster"]["network"]["service_cidr"]
  CLUSTER_NODES_CONTROL_PLANE_CPU = SETTINGS["cluster"]["nodes"]["control_plane"]["cpu"]
  CLUSTER_NODES_CONTROL_PLANE_MEMORY = SETTINGS["cluster"]["nodes"]["control_plane"]["memory"]
  CLUSTER_NODES_CONTROL_PLANE_ENABLE_SCHEDULING = SETTINGS["cluster"]["nodes"]["control_plane"]["enable_scheduling"]
  CLUSTER_NODES_WORKERS_COUNT = SETTINGS["cluster"]["nodes"]["workers"]["count"]
  CLUSTER_NODES_WORKERS_CPU = SETTINGS["cluster"]["nodes"]["workers"]["cpu"]
  CLUSTER_NODES_WORKERS_MEMORY = SETTINGS["cluster"]["nodes"]["workers"]["memory"]
  
  CONFIG_VALID_BOXES = JSON.parse(File.read(File.expand_path("../../config/valid-boxes.json", __FILE__)))
  CONFIG_VALID_PROVIDERS = JSON.parse(File.read(File.expand_path("../../config/requirements.json", __FILE__)))["providers"]
  
  REQUIRED_PLUGINS = JSON.parse(File.read(File.expand_path("../../config/requirements.json", __FILE__)))["vagrant-plugins"]
  
  SCRIPT_COMMON = File.expand_path('../../scripts/common.sh', __FILE__)
  SCRIPT_INSTALL_PYTHON3 = File.expand_path('../../scripts/install-python.sh', __FILE__)
  SCRIPT_KEYBOARD = File.expand_path('../../scripts/keyboard.sh', __FILE__)
  SCRIPT_MASTER = File.expand_path('../../scripts/master.sh', __FILE__)

  VAGRANT_BOOT_TIMEOUT = SETTINGS["vagrant"]["boot_timeout"]
  VAGRANT_BOX_NAME = SETTINGS["vagrant"]["box_name"]
  VAGRANT_BOX_VERSION = SETTINGS["vagrant"]["box_version"]
  VAGRANT_KEYBOARD_LAYOUT = SETTINGS["vagrant"]["keyboard_layout"]
  VAGRANT_IS_DEBUG = ARGV.include?('--debug')
  VAGRANT_IS_UP = ARGV.include?('up')
  VAGRANT_LOG_LEVEL = SETTINGS["vagrant"]["log_level"]
  VAGRANT_PROVIDER = SETTINGS["vagrant"]["provider"]
  VAGRANT_TIMEZONE = SETTINGS["vagrant"]["timezone"]
  
  VERSION = "0.0.1"

  VBOX_VM_GROUP_NAME = SETTINGS["virtual_box"]["vm_group_name"]
  VBOX_NETWORK_HOSTNAME_PREFIX = SETTINGS["virtual_box"]["network"]["hostname_prefix"]
  VBOX_NETWORK_PRIVATE_IP = SETTINGS["virtual_box"]["network"]["private_ip"]

end