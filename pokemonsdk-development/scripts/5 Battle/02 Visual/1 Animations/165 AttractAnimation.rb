module UI

  class StatusAnimation

    class AttractAnimation < StatusAnimation
      # Get the dimension of the Spritesheet
      # @return [Array<Integer, Integer>]
      def status_dimension
        return [18, 17]
      end

      # Get the filename status
      # @return [String]
      def status_filename
        return 'status/attract'
      end
    end
    register(:attract, AttractAnimation)
  end
end