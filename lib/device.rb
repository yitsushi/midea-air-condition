module MideaAirCondition
  # Device representation (now only for status parsing)
  class Device
    attr_reader :data

    def initialize(data)
      @data = data
      @pointer = 0x33
    end

    def power_status
      !(@data[@pointer] & 0x01).zero?
    end

    def temperature
      (@data[@pointer + 1] & 0xf) + 16
    end

    def mode
      (@data[@pointer + 1] & 0xe0) >> 5
    end

    def mode_human
      mode_value = 'unknown'
      mode_value = 'auto' if mode == 1
      mode_value = 'cool' if mode == 2
      mode_value = 'dry' if mode == 3
      mode_value = 'heat' if mode == 4
      mode_value = 'fan' if mode == 5

      mode_value
    end

    def fan_speed
      @data[@pointer + 2] & 0x7f
    end

    def indoor_temperature
      (@data[@pointer + 10] - 50) / 2
    end

    def outdoor_temperature
      (@data[@pointer + 11] - 50) / 2
    end

    def eco
      !((@data[@pointer + 8] & 0x10) >> 4).zero?
    end

    def on_timer
      value = @data[@pointer + 3]
      {
        status:  !((value & 0x80) >> 7).zero?,
        hour:    ((value & 0x7c) >> 2),
        minutes: ((value & 0x3) | ((value & 0xf0)))
      }
    end

    def off_timer
      value = @data[@pointer + 4]
      {
        status:  !((value & 0x80) >> 7).zero?,
        hour:    ((value & 0x7c) >> 2),
        minutes: ((value & 0x3) | ((value & 0xf0)))
      }
    end

    def on_timer_human
      "#{on_timer[:hours]}:#{on_timer[:mins]}"
    end

    def off_timer_human
      "#{off_timer[:hours]}:#{off_timer[:mins]}"
    end
  end
end
