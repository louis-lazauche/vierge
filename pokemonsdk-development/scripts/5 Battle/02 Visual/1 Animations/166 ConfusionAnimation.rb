module UI

  class StatusAnimation

    class ConfusionAnimation < StatusAnimation
      # Return the x offset for the Status Animation
      # @param [Integer]
      def x_offset
        return -4 + Graphics.width / 2 if battle_3d?

        return -4
      end

      # Return the y offset for the Status Animation
      # @param [Integer]
      def y_offset
        return -29 + Graphics.height / 2 if battle_3d?

        return -29
      end

      # Return the duration of the Status Animation
      # @param [Integer]
      def status_duration
        return 2
      end
      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [12, 12]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/confusion'
      end

      def zoom_value
        return 1 if battle_3d? && !enemy?

        return 0.5
      end
    end
    register(:confusion, ConfusionAnimation)
  end
end