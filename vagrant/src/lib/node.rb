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
    config.vm.provision "shell", env: { "IP_NW" => ip_nw, "IP_START" => ip_start, "NUM_WORKER_NODES" => num_worker_nodes }, privileged: true,inline: <<-SHELL
      sudo apt-get update -y
      echo "$IP_NW$((IP_START)) vgk8s-master-node" | sudo tee /etc/hosts
      for i in `seq 1 ${NUM_WORKER_NODES}`; do
        if [ $i -lt 10 ]; then
          echo "$IP_NW$((IP_START+i)) vgk8s-worker-node0${i}" | sudo tee /etc/hosts
        else
          echo "$IP_NW$((IP_START+i)) vgk8s-worker-node${i}" | sudo tee /etc/hosts
        fi
      done
    SHELL

  end

  def self.create_control_server(config)
    config.vm.define vm_name = CONSTANTS::VBOX_NETWORK_HOSTNAME_PREFIX + "master-node", primary: true do |node|
      $logger.debug(self, "Creating control server #{vm_name}...")
      node.vm.boot_timeout = CONSTANTS::VAGRANT_BOOT_TIMEOUT

      node.vm.box = CONSTANTS::VAGRANT_BOX_NAME
      node.vm.box_version = CONSTANTS::VAGRANT_BOX_VERSION
      node.vm.box_check_update = false

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
        vb.default_nic_type = CONSTANTS::VBOX_NETWORK_NIC_TYPE
      end

      $logger.debug(self, "Adding the charts folder sync...")
      node.vm.synced_folder CONSTANTS::CHARTS_FOLDER_HOST, CONSTANTS::CHARTS_FOLDER_TARGET, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=664"]

      $logger.debug(self, "Adding the keyboard layout shell provisioner...")
      Utils.define_shell_provision node, "keyboard layout", path_to_script: CONSTANTS::SCRIPT_KEYBOARD, privileged: false, args: CONSTANTS::VAGRANT_KEYBOARD_LAYOUT

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
      
      $logger.debug(self, "Adding the cp k8s-requirements shell provisioner...")
      Utils.define_shell_provision node, "ansible cp k8s-requirements", script_content: "cp #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements-template.yml #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml", privileged: false
      
      $logger.debug(self, "Adding the replace k8s-requirements shell provisioner...")
      Utils.define_shell_provision node, "ansible replace k8s-requirements", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml -type f -exec sed -i 's|REPLACE_LOCATION|#{CONSTANTS::ANSIBLE_FOLDER_TARGET}|g' {} +", privileged: false

      $logger.debug(self, "Adding the cp playbook init shell provisioner...")
      Utils.define_shell_provision node, "ansible cp playbook init", script_content: "cp #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init-template.yml #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init.yml", privileged: false

      $logger.debug(self, "Adding the cp k8s-requirements shell provisioner...")
      Utils.define_shell_provision node, "ansible cp k8s-requirements", script_content: "cp #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements-template.yml #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml", privileged: false

      $logger.debug(self, "Adding the replace playbook init shell provisioner...")
      Utils.define_shell_provision node, "ansible replace playbook init", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init.yml -type f -exec sed -i 's|REPLACE_MASTER_HOST|#{vm_name}|g' {} +", privileged: false

      use_ansible_local = CONSTANTS::ANSIBLE_PROVIDER == "guest"
      if use_ansible_local
        $logger.debug(self, "Adding the inventory/local shell provisioner...")
        Utils.define_shell_provision node, "inventory/local", script_content: "echo '[local]\n#{vm_name} ansible_connection=local' >> #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/inventory/local", privileged: false
  
        $logger.debug(self, "Adding the replace playbook init shell provisioner...")
        Utils.define_shell_provision node, "ansible replace playbook init", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init.yml -type f -exec sed -i 's|REPLACE_SETTINGS_FILE_PATH|/vagrant/settings.yml|g' {} +", privileged: false
        
        $logger.debug(self, "Adding the replace k8s-requirements shell provisioner...")
        Utils.define_shell_provision node, "ansible replace k8s-requirements", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml -type f -exec sed -i 's|REPLACE_LOCATION|#{CONSTANTS::ANSIBLE_FOLDER_TARGET}|g' {} +", privileged: false

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
        end
      else
        $logger.debug(self, "Adding the inventory/local shell provisioner...")
        Utils.define_shell_provision node, "inventory/local", script_content: "echo '#{vm_name} ansible_host=#{ip}' ansible_user='vagrant' ansible_password='vagrant' >> #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/inventory/local", privileged: false
  
        $logger.debug(self, "Adding the replace playbook init shell provisioner...")
        Utils.define_shell_provision node, "ansible replace playbook init", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init.yml -type f -exec sed -i 's|REPLACE_SETTINGS_FILE_PATH|#{CONSTANTS::SETTINGS_FILE}|g' {} +", privileged: false

        $logger.debug(self, "Adding the replace k8s-requirements shell provisioner...")
        Utils.define_shell_provision node, "ansible replace k8s-requirements", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml -type f -exec sed -i 's|REPLACE_LOCATION|#{CONSTANTS::ANSIBLE_FOLDER_HOST}|g' {} +", privileged: false

        $logger.debug(self, "Adding the ansible provisioner...")
        node.vm.provision "ansible" do |ansible| # https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_common
          ansible.compatibility_mode = "2.0"
          ansible.verbose = true
          ansible.playbook = "#{CONSTANTS::ANSIBLE_FOLDER_HOST}/playbooks/init.yml"
          ansible.vault_password_file = "#{CONSTANTS::ANSIBLE_FOLDER_HOST}/.vault_password"
          ansible.inventory_path = "#{CONSTANTS::ANSIBLE_FOLDER_HOST}/inventory/local"
          ansible.config_file = "#{CONSTANTS::ANSIBLE_FOLDER_HOST}/ansible.cfg"
          ansible.galaxy_role_file = "#{CONSTANTS::ANSIBLE_FOLDER_HOST}/requirements/k8s-requirements.yml"
        end
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

  def self.create_workers(config)
    (1..CONSTANTS::CLUSTER_NODES_WORKERS_COUNT).each do |i|
    
      config.vm.define vm_name = (i < 10 ? CONSTANTS::VBOX_NETWORK_HOSTNAME_PREFIX + "worker-node0#{i}" : CONSTANTS::VBOX_NETWORK_HOSTNAME_PREFIX + "worker-node#{i}") do |node|
        $logger.debug(self, "Creating control server #{vm_name}...")
        node.vm.boot_timeout = CONSTANTS::VAGRANT_BOOT_TIMEOUT

        node.vm.box = CONSTANTS::VAGRANT_BOX_NAME
        node.vm.box_version = CONSTANTS::VAGRANT_BOX_VERSION
        node.vm.box_check_update = false

        node.vm.hostname = vm_name

        $logger.debug(self, "Setting up the network...")
        ip_sections = CONSTANTS::VBOX_NETWORK_PRIVATE_IP.match(/^([0-9.]+\.)([^.]+)$/)
        ip_nw = ip_sections.captures[0]
        ip_start = Integer(ip_sections.captures[1])
        ip = ip_nw + (ip_start + i).to_s
        $logger.key_value(self, "Control server network", "default", Logger::DEBUG)
        node.vm.network "private_network", ip: ip, adapter: 2, nic_type: CONSTANTS::VBOX_NETWORK_NIC_TYPE
        $logger.debug(self, "Network setted up.")

        node.vm.provider :virtualbox do |vb|
          vb.name = vm_name
          vb.memory = CONSTANTS::CLUSTER_NODES_WORKERS_MEMORY
          vb.cpus = CONSTANTS::CLUSTER_NODES_WORKERS_CPU
          vb.customize ["modifyvm", :id, "--groups", ("/" + CONSTANTS::VBOX_VM_GROUP_NAME)]
        end

        $logger.debug(self, "Adding the charts folder sync...")
        node.vm.synced_folder CONSTANTS::CHARTS_FOLDER_HOST, CONSTANTS::CHARTS_FOLDER_TARGET, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=664"]

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
        Utils.define_shell_provision node, "ansible cp playbook init", script_content: "cp #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init-worker-template.yml #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init-worker.yml", privileged: false

        $logger.debug(self, "Adding the replace playbook init shell provisioner...")
        Utils.define_shell_provision node, "ansible replace playbook init", script_content: "find #{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init-worker.yml -type f -exec sed -i 's|REPLACE_WORKER_HOST|#{vm_name}|g' {} +", privileged: false

        $logger.debug(self, "Adding the ansible_local provisioner...")
        node.vm.provision "ansible_local" do |ansible_local| # https://developer.hashicorp.com/vagrant/docs/provisioning/ansible_common
          ansible_local.install = false
          ansible_local.compatibility_mode = "2.0"
          ansible_local.verbose = true
          ansible_local.provisioning_path = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}"
          ansible_local.playbook = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/playbooks/init-worker.yml"
          ansible_local.vault_password_file = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/.vault_password"
          ansible_local.inventory_path = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/inventory/local"
          ansible_local.config_file = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/ansible.cfg"
          ansible_local.galaxy_role_file = "#{CONSTANTS::ANSIBLE_FOLDER_TARGET}/requirements/k8s-requirements.yml"
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