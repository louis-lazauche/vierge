module UI
  # UI Materialization of the Map Overlay
  class MapOverlay
    # Create a new Map Overlay UI
    # @param viewport [Viewport]
    def initialize(viewport)
      @viewport = viewport
      # @type [UISpace]
      @current_preset = nil
    end

    # Update the Overlay animation
    def update
      map_overlay = PFM.game_state.map_overlay
      return dispose unless map_overlay.current_preset

      swap_presets(map_overlay.current_preset) if map_overlay.current_preset.class != @current_preset.class

      @current_preset.update(map_overlay.current_preset)
    end

    # Dispose of map overlay and restore normal shader
    def dispose
      return unless @current_preset
      return if @viewport.disposed?

      @viewport.shader = Shader.create(:map_shader)
      if @viewport.is_a?(Viewport::WithToneAndColors)
        @viewport.shader&.set_float_uniform('color', @viewport.color)
        @viewport.shader&.set_float_uniform('tone', @viewport.tone)
      end
    ensure
      # Always dispose the current preset and clear it
      @current_preset&.dispose
      @current_preset = nil
    end

    private

    # Swap to a new preset and dispose of the previous one
    # @param new_preset [PFM::MapOverlay::PresetBase, nil]
    def swap_presets(new_preset)
      return dispose unless new_preset

      @current_preset&.dispose
      # Duplicate symbol to avoid reference issues
      @current_preset = new_preset.dup
      @current_preset.extend(UISpace)
      # Clear all the unnecessary ivar so default blend_mode and other preset parameter can be applied on next update
      @current_preset.clear_ivar
      # Bind preset to viewport to apply its shader
      @current_preset.bind_to_viewport(@viewport)
    end
  end
end

Hooks.register(Spriteset_Map, :initialize, 'Load Map Overlay') do
  @ui_map_overlay = UI::MapOverlay.new(map_viewport)
end

Hooks.register(Spriteset_Map, :update, 'Update Map Overlay') do
  @ui_map_overlay&.update
end

Hooks.register(Spriteset_Map, :dispose, 'Dispose Map Overlay') do
  @ui_map_overlay&.dispose
  @ui_map_overlay = nil
end
