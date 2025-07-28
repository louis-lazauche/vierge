module PFM
  # Class for the data of Map overlays that will be saved
  class MapOverlay
    # Current preset
    # @return [PresetBase, nil]
    attr_reader :current_preset

    # Change to a new preset
    # @param new_preset [Symbol] Symbol of the preset
    def change_overlay_preset(new_preset)
      raise ArgumentError, "Unregistered Map Overlay Preset :#{new_preset}" unless REGISTERED_PRESETS[new_preset]

      @current_preset = REGISTERED_PRESETS[new_preset].new
    end

    # Erase overlay and dispose resources
    # @return [Boolean] False if overlay was already stopped, true otherwise
    def stop_overlay_preset
      @current_preset = nil
    end
  end

  class << self
    # Accessor for the MapOverlay class
    # @return [Class]
    attr_accessor :map_overlay_class
  end

  class GameState
    # Accessor for the MapOverlay
    # @return [PFM::MapOverlay]
    attr_accessor :map_overlay

    on_initialize(:map_overlay) { @map_overlay = PFM.map_overlay_class.new }
    on_expand_global_variables(:map_overlay) do
      @map_overlay ||= PFM.map_overlay_class.new # Set the value for previous saves
      # Variable containing the map overlay information
      $map_overlay = @map_overlay
    end
  end
end
PFM.map_overlay_class = PFM::MapOverlay
