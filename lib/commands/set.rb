module MideaAirCondition
  module Command
    # Request status of a device
    class Set < BaseCommand
      def turn_on
        @data[0x0a] = 0x40
        @data[0x0b] = 0x43

        temperature 22
        fan_speed 40
      end

      def turn_off
        @data[0x0a] = 0x40
        @data[0x0b] = 0x42

        temperature 22
        fan_speed 40
      end

      def temperature(celsius, mode: 2)
        c = ((mode << 5) & 0xe0) | (celsius & 0xf) | ((celsius << 4) & 0x10)
        @data[0x0c] = c
      end

      def fan_speed(speed)
        @data[0x0d] = speed # & 0x7f
      end
    end
  end
end
