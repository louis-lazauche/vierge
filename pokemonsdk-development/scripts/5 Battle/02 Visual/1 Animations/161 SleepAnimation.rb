module UI

  class StatusAnimation

    class SleepAnimation < StatusAnimation
      # Return the x offset for the Status Animation
      # @param [Integer]
      def x_offset
        return (enemy? ? -40 : 58) + Graphics.width / 2 if battle_3d?

        return enemy? ? -40 : 58
      end

      # Return the y offset for the Status Animation
      # @param [Integer]
      def y_offset
        return (enemy? ? 3 : -15) + Graphics.height / 2 if battle_3d?

        return enemy? ? 3 : -15
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [12, 10]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return enemy? ? 'status/sleep-front' : 'status/sleep-back'
      end
    end
    register(:sleep, SleepAnimation)
  end
end