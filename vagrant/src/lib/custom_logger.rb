require 'logger'
require_relative 'constants'
require_relative 'string'

class CustomFormatter < Logger::Formatter
    def call(severity, time, progname, msg)
        case severity
            when "INFO"
                severity = severity.light_blue
            when "SUCCESS"
                severity = "INFO".green
            when "WARN"
                severity = severity.yellow
            when "ERROR"
                severity = severity.red
            when "FATAL"
                severity = severity.red
            when "ANY"
                severity = severity.green
            when "DEBUG"
                severity = severity.pink
            else
                severity = severity
        end
        
        if msg.is_a?(Hash)
            module_name = "#{msg["module"]}".blue
            message = msg["message"]
            "#{time.strftime("%Y-%m-%d %H:%M:%S")} |#{module_name}| #{severity}: #{message}\n"
        else
            "#{time.strftime("%Y-%m-%d %H:%M:%S")} #{severity}: #{msg}\n"
        end
    end
end
    
class CustomLogger < Logger
    SEVS = %w(DEBUG INFO WARN ERROR FATAL VERBOSE SUCCESS)
    def format_severity(severity)
      SEVS[severity] || 'ANY'
    end

    def get_msg_hash(caller_self, msg)
        {
            "module" => caller_self.name,
            "message" => msg
        }
        # "#{caller_self.name}: #{msg}"
    end

    def get_color_for_severity(severity, msg)
        case severity
            when CustomLogger::INFO
                msg.light_blue
            when CustomLogger::WARN
                msg.yellow
            when CustomLogger::ERROR
                msg.red
            when CustomLogger::FATAL
                msg.red
            when CustomLogger::DEBUG
                msg.pink
            when CustomLogger::SUCCESS
                msg.green
            else
                msg
        end
    end


    @@error_count = 0

    def initialize(*args)
        super(*args)
        self.formatter = CustomFormatter.new
        self.level = _get_logger_level()
    end

    def _get_level_from_word(level_as_word)
        case level_as_word
            when 'DEBUG'
                return Logger::DEBUG
            when 'INFO'
                return Logger::INFO
            when 'WARN'
                return Logger::WARN
            when 'ERROR'
                return Logger::ERROR
            when 'FATAL'
                return Logger::FATAL
            else
                add(CustomLogger::WARN, nil, "Invalid LOGGER_LEVEL log level '#{level_as_word}', valid values are: DEBUG, INFO, WARN, ERROR, FATAL. Defaulting to INFO.")
                return Logger::INFO
        end
    end

    def _get_logger_level()
        if CONSTANTS::VAGRANT_IS_DEBUG
            return Logger::DEBUG
        else
            return _get_level_from_word(CONSTANTS::VAGRANT_LOG_LEVEL)
        end
        return Logger::INFO
    end

    def _ignore_logs_if_not_up
        if not CONSTANTS::VAGRANT_IS_UP and @@error_count == 0; return true; end
        return false
    end


    def debug(caller_self, msg)
        if _ignore_logs_if_not_up; return; end
        msg = get_msg_hash(caller_self, msg.pink)
        super(msg)
    end

    def info(caller_self, msg)
        if _ignore_logs_if_not_up; return; end
        msg = get_msg_hash(caller_self, msg.light_blue)
        super(msg)
    end

    def warn(caller_self, msg)
        if _ignore_logs_if_not_up; return; end
        msg = get_msg_hash(caller_self, msg.yellow)
        super(msg)
    end

    def error(caller_self, msg)
        @@error_count += 1

        msg = get_msg_hash(caller_self, msg.red)
        super(msg)
    end

    def log_error_and_raise_exception(caller_self, msg)
        @@error_count += 1
        msg = get_msg_hash(caller_self, msg.red)
        add(CustomLogger::ERROR, nil, msg)
        raise Vagrant::Errors::VagrantError.new, msg["message"].red
    end

    def fatal(caller_self, msg)
        @@error_count += 1

        msg = get_msg_hash(caller_self, msg.red)
        super(msg)
    end

    def unknown(caller_self, msg)
        if _ignore_logs_if_not_up; return; end
        msg = get_msg_hash(caller_self, msg.green)
        super(msg)
    end

    def success(caller_self, progname = nil, &block)
        if _ignore_logs_if_not_up; return; end
        msg = get_msg_hash(caller_self, progname.green)
        add(6, nil, msg, &block)
    end

    def key_value(caller_self, key, value, severity = Logger::INFO, &block)
        if _ignore_logs_if_not_up; return; end
        key = get_color_for_severity(severity, key)
        value = get_color_for_severity(severity, "#{value}")
        msg = get_msg_hash(caller_self, "#{key}: #{value}")
        add(severity, nil, msg, &block)
    end

end

$logger = CustomLogger.new(STDOUT)
