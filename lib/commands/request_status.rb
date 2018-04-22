module MideaAirCondition
  module Command
    # Request status of a device
    class RequestStatus < BaseCommand
      def fill
        @data[0x0a] = 0x40
      end
    end
  end
end
