module MideaAirCondition
  module Command
    # Base Command class
    class BaseCommand
      # Default device type: 0xAC
      def initialize(device_type: 0xAC)
        @data = [0xaa, 0x23, device_type, 0x00, 0x00, 0x00, 0x00, 0x00]

        @data += [
          0x03, 0x02, 0xff, 0x81, 0x00, 0xff, 0x03, 0xff,
          0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ]

        fill
      end

      def finalize(security)
        # Add command sequence number
        # Can't be lower than 3
        @data << 0x03
        @data << security.crc8(@data[0x10..(@data.length - 1)])
        @data[0x01] = @data.length

        @data
      end

      private

      def fill; end
    end
  end
end
