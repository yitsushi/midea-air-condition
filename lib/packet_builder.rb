# frozen_string_literal: true

module MideaAirCondition
  # This is where we build our packets
  class PacketBuilder
    def initialize(security)
      @security = security
      @command = []

      populate_header_data

      # Maybe this one is the client id
      # In a response it's the device id
      # and the first six bytes are the same
      @packet += [0xc6, 0x79, 0x00, 0x00, 0x00, 0x05, 0x0a, 0x00]

      add_unknown_section
    end

    def add_command(command)
      raise Exception, 'Invalid argument' if command.is_a?(Command)

      @command += command.finalize(@security)
    end

    def finalize
      @packet += @command
      @packet << @security.checksum(@command[1..(@command.length - 1)])
      @packet << 0x00

      # Add padding + update packet length
      @packet += [0] * (44 - @command.length)
      @packet += [0]
      @packet[0x04] = @packet.length

      @packet
    end

    def populate_header_data
      # was always fix for me except the length byte
      @packet  = [0x5a, 0x5a, 0x01, 0x11, 0x5c, 0x00, 0x20, 0x00]

      # was different for status and power
      # Set Temp
      # @packet += [0x12, 0x00, 0x00, 0x00, 0x6f, 0x33, 0x0c, 0x00]
      # Status
      # @packet += [0x01, 0x00, 0x00, 0x00, 0x8d, 0x0f, 0x17, 0x02]
      # Power
      # @packet += [0x12, 0x00, 0x00, 0x00, 0x6f, 0x33, 0x0c, 0x00]
      # now just use 0x00 * 8
      @packet += [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

      # was always fix for me
      @packet += [0x0e, 0x03, 0x12, 0x14]
    end

    def add_unknown_section
      @packet += [
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x02, 0x00, 0x00, 0x00
      ]
    end
  end
end
