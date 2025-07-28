module UI

  class StatusAnimation

    class PoisonAnimation < StatusAnimation
      # Return the x offset for the Status Animation
      # @param [Integer]
      def x_offset
        return -3 + Graphics.width / 2 if battle_3d?

        return -3
      end

      # Return the y offset for the Status Animation
      # @param [Integer]
      def y_offset
        return 3 + Graphics.height / 2 if battle_3d?

        return 3
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [12, 10]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/poison'
      end

      # Return the duration of the Status Animation
      # @param [Integer]
      def status_duration
        return 1.2
      end
    end
    register(:poison, PoisonAnimation)
    register(:toxic, PoisonAnimation)
  end
end