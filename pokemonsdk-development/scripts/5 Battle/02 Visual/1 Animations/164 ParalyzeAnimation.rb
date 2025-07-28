module UI

  class StatusAnimation

    class ParalyzeAnimation < StatusAnimation
      # Return the y offset for the Status Animation
      # @param [Integer]
      def y_offset
        return 3 + Graphics.height / 2 if battle_3d?

        return 3
      end

      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [10, 8]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/paralysis'
      end
    end
    register(:paralysis, ParalyzeAnimation)
  end
end