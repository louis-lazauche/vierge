module UI

  class StatusAnimation

    class BurnAnimation < StatusAnimation
      # Return the x offset for the Status Animation
      # @param [Integer]
      def x_offset
        return 2 + Graphics.width / 2 if battle_3d?

        return 2
      end

      # Return the y offset for the Status Animation
      # @param [Integer]
      def y_offset
        return 44 + Graphics.height / 2 if battle_3d?

        return 44
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [9, 8]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/burn'
      end
    end
    register(:burn, BurnAnimation)
  end
end