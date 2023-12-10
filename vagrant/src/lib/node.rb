require_relative 'constants'
require_relative 'utils'

module Node

  @@control_server_data = {}
  @@workers_data = []


  def self.update_and_define_hosts(config)
    ip_sections = CONSTANTS::VBOX_NETWORK_PRIVATE_IP.match(/^([0-9.]+\.)([^.]+)$/)
    ip_nw = ip_sections.captures[0]
    ip_start = Integer(ip_sections.captures[1])
    prefix = CONSTANTS::VBOX_NETWORK_HOSTNAME_PREFIX
    num_worker_nodes = CONSTANTS::CLUSTER_NODES_WORKERS_COUNT

    # TODO: verify working as expected
    config.vm.provision "shell", env: { "IP_NW" => ip_nw, "IP_START" => ip_start, "NUM_WORKER_NODES" => num_worker_nodes }, inline: <<-SHELL
      apt-get update -y
      echo "$IP_NW$((IP_START)) vgk8s-master-node" >> /etc/hosts
      for i in `seq 1 ${NUM_WORKER_NODES}`; do
        echo "$IP_NW$((IP_START+i)) vgk8s-worker-node0${i}" >> /etc/hosts
      done
    SHELL

  end

  def self.create_control_server(config)
    config.vm.define vm_name = CONSTANTS::VBOX_NETWORK_HOSTNAME_PREFIX + "master-node", primary: true do |node|
      $logger.debug(self, "Creating control server #{vm_name}...")
      node.vm.boot_timeout = CONSTANTS::VAGRANT_BOOT_TIMEOUT

      node.vm.box = CONSTANTS::VAGRANT_BOX_NAME
      node.vm.box_version = CONSTANTS::VAGRANT_BOX_VERSION
      node.vm.box_check_update = true

      node.vm.hostname = vm_name

      $logger.debug(self, "Setting up the network...")
      ip = CONSTANTS::VBOX_NETWORK_PRIVATE_IP
      
      $logger.key_value(self, "Control server network", "default", Logger::DEBUG)
      node.vm.network "private_network", ip: ip
      
      $logger.debug(self, "Network setted up.")

      node.vm.provider :virtualbox do |vb|
        vb.name = vm_name
        vb.memory = CONSTANTS::CLUSTER_NODES_CONTROL_PLANE_MEMORY
        vb.cpus = CONSTANTS::CLUSTER_NODES_CONTROL_PLANE_CPU
        vb.customize ["modifyvm", :id, "--groups", ("/" + CONSTANTS::VBOX_VM_GROUP_NAME)]
      end

      $logger.debug(self, "Adding the keyboard layout shell provisioner...")
      Utils.define_shell_provision node, "keyboard layout", path_to_script: CONSTANTS::SCRIPT_KEYBOARD, privileged: false

      $logger.debug(self, "Adding the apt update shell provisioner...")
      Utils.define_shell_provision node, "apt update", script_content: "apt update -y", privileged: true

      $logger.debug(self, "Adding the python3 installation shell provisioner...")
      Utils.define_shell_provision node, "python3 installation", path_to_script: CONSTANTS::SCRIPT_INSTALL_PYTHON3, privileged: false

      $logger.debug(self, "Adding the ansible-core installation shell provisioner...")
      Utils.define_shell_provision node, "ansible-core installation", script_content: "pip3 install --user ansible-core==#{CONSTANTS::ANSIBLE_CORE_VERSION}", privileged: false

      $logger.debug(self, "Adding the ansible folder sync...")
      node.vm.synced_folder CONSTANTS::ANSIBLE_FOLDER_HOST, CONSTANTS::ANSIBLE_FOLDER_TARGET, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=664"]

      $logger.debug(self, "Adding the clean inventory/local shell provisioner...")
      Utils.define_shell_provision node, "clean inventory/local", script_content: "rm -rf #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/inventory/local && touch #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/inventory/local", privileged: false
      
      $logger.debug(self, "Adding the inventory/local shell provisioner...")
      Utils.define_shell_provision node, "inventory/local", script_content: "echo '[local]\n#{vm_name} ansible_connection=local' >> #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/inventory/local", privileged: false

      $logger.debug(self, "Adding the cp k8s-requirements shell provisioner...")
      Utils.define_shell_provision node, "ansible cp k8s-requirements", script_content: "cp #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements-template.yml #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml", privileged: false
      
      $logger.debug(self, "Adding the replace k8s-requirements shell provisioner...")
      Utils.define_shell_provision node, "ansible replace k8s-requirements", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml -type f -exec sed -i 's|REPLACE_LOCATION|#{CONSTANTS::ANSIBLE_FOLDER_TARGET}|g' {} +", privileged: false

      $logger.debug(self, "Adding the cp playbook init shell provisioner...")
      Utils.define_shell_provision node, "ansible cp playbook init", script_content: "cp #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init-template.yml #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init.yml", privileged: false

      $logger.debug(self, "Adding the replace playbook init shell provisioner...")
      Utils.define_shell_provision node, "ansible replace playbook init", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init.yml -type f -exec sed -i 's|REPLACE_MASTER_HOST|#{vm_name}|g' {} +", privileged: false

      $logger.debug(self, "Adding the ansible_local provisioner...")
      node.vm.provision "ansible_local" do |ansible_local| # https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_common
        ansible_local.install = false
        ansible_local.compatibility_mode = "2.0"
        ansible_local.verbose = true
        ansible_local.provisioning_path = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}"
        ansible_local.playbook = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init.yml"
        ansible_local.vault_password_file = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/.vault_password"
        ansible_local.inventory_path = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/inventory/local"
        ansible_local.config_file = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/ansible.cfg"
        ansible_local.galaxy_role_file = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml"
        # ansible_local.galaxy_roles_path = "/home/vagrant/.ansible/collections/" TODO: verify if we can delete it
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
    if !CONSTANTS::VAGRANT_IS_UP; return; end
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