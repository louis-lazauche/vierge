class Interpreter
  # Start an overlay preset
  # @example S.MI.start_overlay(:fog) (in console)
  # @example start_overlay(:fog) (in an event)
  # @param preset [Symbol] Symbol of an overlay preset
  def start_overlay(preset)
    PFM.game_state.map_overlay.change_overlay_preset(preset)
  end

  # Clear overlay
  # @example S.MI.stop_overlay (in console)
  # @example stop_overlay (in event)
  def stop_overlay
    PFM.game_state.map_overlay.stop_overlay_preset
  end

  # Get the current overlay preset
  # @return [PFM::MapOverlay::PresetBase, nil]
  def current_overlay_preset
    return PFM.game_state.map_overlay.current_preset
  end
end
