# frozen_string_literal: true

module MideaAirCondition
  module Command
    # Request status of a device
    class Set < BaseCommand
      def turn_on
        @data[0x0b] = 0x43
      end

      def turn_off
        @data[0x0b] = 0x42
      end

      def temperature(value, mode: 1)
        c = ((mode << 5) & 0xe0) | (value & 0xf) | ((value << 4) & 0x10)
        @data[0x0c] = c
      end

      def unit(value)
        unit_value = 0
        unit_value = 1 if value == 'F'

        # (byte)(
        #     this.sleepFunc & 0x1
        #   | this.tubro << 1 & 0x2
        #   | this.tempUnit << 2 & 0x4
        #   | this.catchCold << 3 & 0x8
        #   | this.nightLight << 4 & 0x10
        #   | this.peakElec << 5 & 0x20
        #   | this.dusFull << 6 & 0x40
        #   | this.cleanFanTime << 7 & 0x80)
        # );
        mask = 0xff ^ 0x4
        @data[0x13] = (@data[0x13] & mask) | (unit_value << 2 & 0x4)
      end

      def fan_speed(speed)
        @data[0x0d] = speed
      end

      private

      def fill
        @data[0x0a] = 0x40

        temperature 22
        fan_speed 40
      end
    end
  end
end
