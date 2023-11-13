# Extend the String class with colorization methods
class String
    CAN_COLORIZE = STDOUT.tty? && ENV['TERM'] != 'dumb'
    # colorization
    def colorize(color_code)
      return self unless CAN_COLORIZE
      "\e[#{color_code}m#{self}\e[0m"
    end
  
    def red
      colorize(31)
    end
  
    def green
      colorize(32)
    end
  
    def yellow
      colorize(33)
    end
  
    def blue
      colorize(34)
    end
  
    def pink
      colorize(35)
    end
  
    def light_blue
      colorize(36)
    end
  end