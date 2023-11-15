require_relative 'constants'
require_relative 'utils'

module Node

  @@control_server_data = {}
  @@workers_data = []

  def self.define_global_variables_from_environment_variables
    $logger.info(self, "Defining global variables using environment variables...")

    # Common variables
    $vm_box = ENV.fetch('MASTER_BOX_IMAGE_NAME', CONSTANTS::DEFAULT_MASTER_BOX_IMAGE_NAME)
    $vm_box_version = ENV.fetch('MASTER_BOX_IMAGE_VERSION', CONSTANTS::DEFAULT_MASTER_BOX_IMAGE_VERSION)
    $subnet = ENV.fetch('MASTER_SUBNET',CONSTANTS::DEFAULT_MASTER_SUBNET)

    # Master variables
    $master_memory = ENV.fetch('MASTER_MEMORY', CONSTANTS::DEFAULT_MASTER_MEMORY).to_i
    $master_cpus = ENV.fetch('MASTER_CPUS', CONSTANTS::DEFAULT_MASTER_CPUS).to_i
    $master_disk_size = ENV.fetch('MASTER_DISK_SIZE', CONSTANTS::DEFAULT_MASTER_DISK_SIZE)


    $logger.key_value(self, "MASTER_BOX_IMAGE_NAME", $vm_box, Logger::DEBUG)
    $logger.key_value(self, "MASTER_BOX_IMAGE_VERSION", $vm_box_version, Logger::DEBUG)
    $logger.key_value(self, "MASTER_MEMORY", $master_memory, Logger::DEBUG)
    $logger.key_value(self, "MASTER_CPUS", $master_cpus, Logger::DEBUG)
    $logger.key_value(self, "MASTER_DISK_SIZE", $master_disk_size, Logger::DEBUG)

    $logger.success(self, "Global variables defined.")
  end

  def self.create_control_server(config)
    config.vm.define vm_name = CONSTANTS::VM_CONTROL_SERVER_NAME, primary: true do |node|
      $logger.debug(self, "Creating control server #{vm_name}...")
      # node.vm.boot_timeout = CONSTANTS::BOOT_TIMEOUT

      node.vm.box = $vm_box
      node.vm.box_version = $vm_box_version
      node.vm.hostname = vm_name
      node.disksize.size = $master_disk_size # not supported by hyperv provider

      $logger.debug(self, "Setting up the network...")
      ip = "#{$subnet}.100"
      
      $logger.key_value(self, "Control server network", "default", Logger::DEBUG)
      node.vm.network "private_network", ip: ip #, bridge: "InternalSwitch"
      
      $logger.debug(self, "Network set up.")

      node.vm.provider :virtualbox do |vb|
        vb.name = vm_name
        vb.memory = $master_memory
        vb.cpus = $master_cpus
        vb.gui = false

        vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
        vb.customize ["modifyvm", :id, "--vram", "8"]
        vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
        vb.customize ["modifyvm", :id, "--audio", "none"]
        vb.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
        vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
      end

      $logger.debug(self, "Adding the apt update shell provisioner...")
      Utils.define_shell_provision node, "apt update", script_content: "apt update -y", privileged: true

      $logger.debug(self, "Adding the python3 installation shell provisioner...")
      Utils.define_shell_provision node, "python3 installation", path_to_script: CONSTANTS::SCRIPT_INSTALL_PYTHON3, privileged: false

      $logger.debug(self, "Adding the ansible-core installation shell provisioner...")
      Utils.define_shell_provision node, "ansible-core installation", script_content: "pip3 install --user ansible-core==#{CONSTANTS::ANSIBLE_CORE_VERSION}", privileged: false

      $logger.debug(self, "Setting up the shared folder permissions...")
      provider_name = Utils.get_provider_name()
      
      if provider_name == "virtualbox"
        node.vm.synced_folder ENV['WORKING_DIRECTORY'], CONSTANTS::VM_SYNCED_FOLDER_WORKING_DIRECTORY, create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=664"]
        node.vm.synced_folder ".", CONSTANTS::VM_SYNCED_FOLDER_VAGRANT, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=664"]
        node.vm.synced_folder CONSTANTS::ANSIBLE_FOLDER_HOST, CONSTANTS::ANSIBLE_FOLDER_TARGET, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=664"]
      end
      $logger.debug(self, "Shared folder permissions setted up.")

      $logger.debug(self, "Adding the ansible_local provisioner...")
      node.vm.provision "ansible_local" do |ansible_local| # https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_common
        ansible_local.install = false
        ansible_local.compatibility_mode = "2.0"
        ansible_local.verbose = true
        ansible_local.provisioning_path = "/ansible"
        ansible_local.playbook = "/ansible/playbooks/init.yml"
        ansible_local.vault_password_file = "/ansible/.vault_password"
        ansible_local.inventory_path = "/ansible/inventory/local"
        ansible_local.galaxy_role_file = "/ansible/requirements/k8s-requirements.yml"
      end
      
      $logger.key_value(self, "IP", ip, Logger::INFO)
      $logger.success(self, "Control server #{vm_name} created.")
      
      @@control_server_data = {
        "ip" => ip,
        "vm_name" => vm_name
      }
      _log_nodes_info()
    end
    
    
  end
  
  
  def self._log_nodes_info
    if !CONSTANTS::IS_UP; return; end
    if @@control_server_data.empty?
      $logger.log_error_and_raise_exception(self, "Control server data is empty")
    end
    
    $logger.success(self, "Control server info:")
    $logger.key_value(self, "VM_NAME", @@control_server_data["vm_name"], Logger::INFO)
    $logger.key_value(self, "IP", @@control_server_data["ip"], Logger::INFO)

    if !@@workers_data.empty?
      $logger.success(self, "Workers info:")
      $logger.key_value(self, "NUM_WORKERS", @@workers_data.length, Logger::INFO)

      @@workers_data.each_with_index do |worker, index|
        $logger.info(self, "Worker #{index+1}:")
        $logger.key_value(self, "VM_NAME", worker["vm_name"], Logger::INFO)
        $logger.key_value(self, "IP", worker["ip"], Logger::INFO)
      end
    end
  end

end