module UI
  module Casino
    # Base UI for the Slot Machines
    class BaseUI < GenericBase
      private

      # Get the filename of the background
      # @return [String] filename of the background
      def background_filename
        return 'casino/base'
      end
    end
  end
end
