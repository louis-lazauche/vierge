module UI

  class StatusAnimation

    class FreezeAnimation < StatusAnimation
      # Return the x offset for the Status Animation
      # @param [Integer]
      def x_offset
        return -3 + Graphics.width / 2 if battle_3d?

        return -3
      end

      # Return the y offset for the Status Animation
      # @param [Integer]
      def y_offset
        return 31 + Graphics.height / 2 if battle_3d?

        return 31
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [16, 15]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/freeze'
      end
    end
    register(:freeze, FreezeAnimation)
  end
end