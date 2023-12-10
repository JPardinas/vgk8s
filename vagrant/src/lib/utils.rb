require_relative 'constants'

module Utils
    # define count attribute for class and initialize it to 0
    @@count = 0

    def self.get_provider_name
        provider_name = CONSTANTS::VAGRANT_PROVIDER
        ARGV.each do|a|
            if a.include?('--provider=')
                provider_name = a.split('=')[1]
            end
        end
        return provider_name
    end

    def self.print_banner
        # define multine string
        banner = <<~BANNER
#     #  #####  #    #   #####   #####
#     # #     # #   #   #     # #     #
#     # #       #  #    #     # #
#     # #  #### ###      #####   #####
 #   #  #     # #  #    #     #       #
  # #   #     # #   #   #     # #     #
   #     #####  #    #   #####   #####
v#{CONSTANTS::VERSION}
        BANNER
        $logger.info(self, "")
        banner.each_line do |line|
            line = line.chomp
            $logger.info(self, line)
        end
        $logger.info(self, "")

    end

    def self.define_shell_provision(node, script_title,  options = {})
        # Expected keys in the options hash:
        # - :path_to_script (String, path to the script file) - Optional
        # - :script_content (String, content of the script) - Optional
        # - :privileged (Boolean, whether the provisioner should run with elevated privileges) - Optional, default: false
        # - :args (string or Array, arguments to pass to the script) - Optional
        privileged = options[:privileged] || false
        args = options[:args] || nil

        if options[:path_to_script].nil? && options[:script_content].nil?
            $logger.log_error_and_raise_exception(self, "Either script_content or path_to_script must be defined")
        elsif options[:path_to_script] && options[:script_content]
            $logger.log_error_and_raise_exception(self, "Either script_content or path_to_script must be defined, but not both")
        end
        
        if options[:path_to_script]
            path_to_script = options[:path_to_script]
            $logger.debug(self, "Reading script content from #{path_to_script}")
            script_content = File.read(path_to_script)
        elsif options[:script_content]
            script_content = options[:script_content]
        end

        $logger.debug(self, "Adding shell provisioner #{@@count += 1}: #{script_title}")
        title = "VGk8s".blue + " | " + "Shell provisioner #{@@count}".light_blue + " | " + "#{script_title}".yellow + " | " + "Privileged: #{privileged}".yellow
        echo_title = "echo \"#{title} | Start\""
        echo_title_end = "echo \"#{title} | End\""
        script_content = "#{echo_title}\n#{script_content}\n#{echo_title_end}"
        node.vm.provision "shell", inline: script_content, privileged: privileged, args: args
    end

end