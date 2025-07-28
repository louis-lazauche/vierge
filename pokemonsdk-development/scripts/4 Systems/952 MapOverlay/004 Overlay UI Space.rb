module UI
  class MapOverlay
    # Module that enable the UI Space related function of each presets
    module UISpace
      IVAR_TO_PRESERVE = %i[@time @paused]

      # Set all the IVar to nil (aside those mentioned in `IVAR_TO_PRESERVE`)
      def clear_ivar
        ivar_to_remove = instance_variables.reject { |i| IVAR_TO_PRESERVE.include?(i) }
        ivar_to_remove.each { |i| instance_variable_set(i, nil) }
      end

      # Set the preset related variables
      # @param viewport [Viewport]
      def bind_to_viewport(viewport)
        @shader = Shader.create(shader_name)
        viewport.shader = @shader
        if viewport.is_a?(Viewport::WithToneAndColors)
          @shader.set_float_uniform('color', viewport.color)
          @shader.set_float_uniform('tone', viewport.tone)
        end
      end

      # Update the preset
      # @param preset [PFM::MapOverlay::PresetBase]
      def update(preset)
        super
      end

      # Dispose the preset
      def dispose
        super
      end
    end
  end
end
