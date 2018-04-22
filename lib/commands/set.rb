module MideaAirCondition
  module Command
    # Request status of a device
    class Set < BaseCommand
      def turn_on
        @data[0x3] |= 0x1
      end

      def turn_off
        @data[0x3] &= 0x1
      end

      def temperature=(celsius, mode: 2)
        c = ((mode << 5) & 0xe0) | (celsius & 0xf) | ((celsius << 4) & 0x10)
        @data[0x04] = c
      end
    end
  end
end
