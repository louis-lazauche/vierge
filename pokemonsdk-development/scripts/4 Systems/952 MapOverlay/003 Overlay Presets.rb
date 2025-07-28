module PFM
  class MapOverlay
    # List of registered presets
    # @return [Hash<Symbol => Class>]
    REGISTERED_PRESETS = {}

    class << self
      # Register a preset
      # @param preset_name [Symbol]
      # @param klass [Class]
      def register_preset(preset_name, klass)
        REGISTERED_PRESETS[preset_name] = klass
      end
    end

    # Base preset of the map overlay
    class PresetBase
      # Minimum value of time in MapOverlay
      TMIN = 0
      # Maximum value of time in MapOverlay
      TMAX = 100
      # List of allowed blend modes
      ALLOWED_BLEND_MODES = %i[normal add subtract multiply overlay screen]

      # Get the blend mode
      # @return [Symbol]
      attr_reader :blend_mode

      # Set the blend mode
      # @param blend_mode [Symbol]
      def blend_mode=(blend_mode)
        unless ALLOWED_BLEND_MODES.include?(blend_mode)
          raise ArgumentError, "Provided with invalid blend mode value: #{blend_mode}; expected #{ALLOWED_BLEND_MODES.to_a.join(', ')}"
        end

        @blend_mode = blend_mode
      end

      # Get the opacity
      # @return [Float]
      attr_reader :opacity

      # Set the opacity
      # @param opacity [Float, Integer]
      def opacity=(opacity)
        unless opacity.between?(0, 1)
          raise ArgumentError, "Provided with invalid opacity: #{opacity}, expected 0.0 upto 1.0"
        end

        @opacity = opacity
      end

      # Get the resolution
      # @return [Array<Integer>]
      attr_reader :resolution

      # Access the paused attribute
      # @return [Boolean]
      attr_accessor :paused

      private

      # Initialize the preset
      def initialize
        @blend_mode = ALLOWED_BLEND_MODES.first
        @time = t_min
        @opacity = 1
        config = Viewport::CONFIGS[:main] # TODO: Provide a way to agree with the viewport setting used by Spriteset_Map
        @resolution = [config[:width], config[:height]]
        @paused = !has_animation?
      end

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_static_image
      end

      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return false
      end

      # Return the t_min value for animation
      # @return [Numeric]
      def t_min
        return TMIN
      end

      # Return the t_max value for animation
      # @return [Numeric]
      def t_max
        return TMAX
      end

      # Update the preset in UI space
      # @param preset [PresetBase]
      def update(preset)
        update_opacity(preset)
        update_blend_mode(preset)
        update_time(preset)
      end

      # Update the opacity in UI Space
      # @param preset [PresetBase]
      def update_opacity(preset)
        return if preset.opacity == @opacity

        @shader.set_float_uniform('opacity', @opacity = preset.opacity)
      end

      # Update the blend_mode in UI Space
      # @param preset [PresetBase]
      def update_blend_mode(preset)
        return if preset.blend_mode == @blend_mode

        @blend_mode = preset.blend_mode
        @shader.set_int_uniform('blend_mode', ALLOWED_BLEND_MODES.index(@blend_mode))
      end

      # Update the time parameter
      # @param preset [PresetBase]
      def update_time(preset)
        current_elapsed = $scene.clock.elapsed_time
        return if preset.paused

        if @last_elapsed
          if current_elapsed >= @last_elapsed
            delta = (current_elapsed - @last_elapsed) / 2
          else
            delta = 0.008 # LEGACY: Value defined to "avoid stuttering" after pause
          end
          @time += delta
          @time = t_min + (@time - t_max) if @time > t_max
        end

        @shader.set_float_uniform('time', @time)
      ensure
        @last_elapsed = current_elapsed
      end

      # Dispose itself in UI space
      def dispose
        @shader = nil
      end
    end

    # Abstraction for shader using the 'sample_color' uniform
    module PresetWithSampleColor
      # Get or set the sample_color
      # @return [Color]
      attr_accessor :sample_color

      private

      # Update the preset in UI space
      # @param preset [PresetWithSampleColor]
      def update(preset)
        super
        update_sample_color(preset)
      end

      # Update sample_color texture in UI space
      # @param preset [PresetWithSampleColor]
      def update_sample_color(preset)
        return if @sample_color == preset.sample_color

        @shader.set_float_uniform('sample_color', @sample_color = preset.sample_color.dup)
      end
    end

    # Static image overlay
    class PresetStaticImage < PresetBase
      # Get or set the extra texture name
      # @return [String]
      attr_accessor :extra_texture_name

      # Get or set the distance factor
      # @return [Numeric]
      attr_accessor :distance_factor

      private

      # Initialize the Static Image preset
      def initialize
        super
        @extra_texture_name = 'fog_base'
        @distance_factor = 1.5
      end

      # Update the preset in UI space
      # @param preset [PresetStaticImage]
      def update(preset)
        super
        update_distance_factor(preset)
        update_extra_texture(preset)
      end

      # Update extra texture in UI space
      # @param preset [PresetStaticImage]
      def update_extra_texture(preset)
        return if @extra_texture_name == preset.extra_texture_name && @extra_texture

        @extra_texture&.dispose unless @extra_texture&.disposed?
        @extra_texture = RPG::Cache.fog(@extra_texture_name = preset.extra_texture_name)
        @shader.set_texture_uniform('extra_texture', @extra_texture)
      end

      # Update the distance factor
      # @param preset [PresetStaticImage]
      def update_distance_factor(preset)
        return if preset.distance_factor == @distance_factor

        @shader.set_float_uniform('dist_factor', @distance_factor = preset.distance_factor)
      end

      def dispose
        super
        @extra_texture&.dispose unless @extra_texture&.disposed?
      end
    end
    register_preset(:static_image, PresetStaticImage)

    # Scroll image preset
    class PresetScrollImage < PresetStaticImage
      # Get or set the scroll direction
      # @return [Array]
      attr_accessor :direction1

      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_scroll
      end

      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return true
      end

      # Initialize the Scroll Image preset
      def initialize
        super
        @distance_factor = 1.5
        @extra_texture_name = 'noise_texture'
        @direction1 = [0.1, 0.1]
      end

      # Update the preset
      # @param preset [PresetScrollImage]
      def update(preset)
        super
        update_direction1(preset)
      end

      # Update the direction1
      # @param preset [PresetScrollImage]
      def update_direction1(preset)
        return if preset.direction1 == @direction1

        @shader.set_float_uniform('direction1', @distance_factor = preset.distance_factor)
      end
    end
    register_preset(:scroll, PresetScrollImage)

    # Water overlay
    class PresetWaterOverlay < PresetBase
      # Get or set the noise texture name
      # @return [String]
      attr_accessor :noise_texture_name

      # Get or set the color gradient texture name
      # @return [String]
      attr_accessor :color_gradient_texture_name

      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_water
      end

      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return true
      end

      # Initialize the Water Overlay preset
      def initialize
        super
        @noise_texture_name = 'noise_texture'
        @color_gradient_texture_name = 'water_color_gradient'
        @blend_mode = :multiply
      end

      # Update the preset in UI space
      # @param preset [PresetWaterOverlay]
      def update(preset)
        super
        update_noise_texture(preset)
        update_color_gradient_texture(preset)
      end

      # Update noise texture in UI space
      # @param preset [PresetWaterOverlay]
      def update_noise_texture(preset)
        return if @noise_texture_name == preset.noise_texture_name

        @noise_texture&.dispose unless @noise_texture&.disposed?
        @noise_texture = RPG::Cache.fog(@noise_texture_name = preset.noise_texture_name)
        @shader.set_texture_uniform('noise', @noise_texture)
      end

      # Update color_gradient texture in UI space
      # @param preset [PresetWaterOverlay]
      def update_color_gradient_texture(preset)
        return if @color_gradient_texture_name == preset.color_gradient_texture_name

        @color_gradient_texture&.dispose unless @color_gradient_texture&.disposed?
        @color_gradient_texture = RPG::Cache.fog(@color_gradient_texture_name = preset.color_gradient_texture_name)
        @shader.set_texture_uniform('color_gradient', @color_gradient_texture)
      end

      def dispose
        super
        @noise_texture&.dispose unless @noise_texture&.disposed?
        @color_gradient_texture&.dispose unless @color_gradient_texture&.disposed?
      end
    end
    register_preset(:water, PresetWaterOverlay)

    # Fog overlay
    class PresetFogOverlay < PresetBase
      prepend PresetWithSampleColor

      # Get or set the noise texture name
      # @return [String]
      attr_accessor :noise_texture_name

      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_fog
      end

      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return true
      end

      # Initialize the Fog Overlay preset
      def initialize
        super
        @noise_texture_name = 'noise_texture'
        @sample_color = Color.new(204, 204, 204)
      end

      # Update the preset in UI space
      # @param preset [PresetFogOverlay]
      def update(preset)
        super
        update_noise_texture(preset)
      end

      # Update noise texture in UI space
      # @param preset [PresetFogOverlay]
      def update_noise_texture(preset)
        return if @noise_texture_name == preset.noise_texture_name

        @noise_texture&.dispose unless @noise_texture&.disposed?
        @noise_texture = RPG::Cache.fog(@noise_texture_name = preset.noise_texture_name)
        @shader.set_texture_uniform('noise', @noise_texture)
      end

      def dispose
        super
        @noise_texture&.dispose unless @noise_texture&.disposed?
      end
    end
    register_preset(:fog, PresetFogOverlay)

    # Nausea overlay
    class PresetNausea < PresetBase
      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_nausea
      end

      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return true
      end
    end
    register_preset(:nausea, PresetNausea)

    # Ripple overlay
    class PresetRippleOverlay < PresetBase
      prepend PresetWithSampleColor

      # Get or set the position
      # @return [PFM::MapOverlay::UVResolver]
      attr_accessor :position

      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_ripple
      end

      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return true
      end

      # Initialize the Ripple preset
      def initialize
        super
        @sample_color = Color.new(0, 26, 26, 128)
        @position = UVResolver.new(:game_player)
      end

      # Update the preset in UI space
      # @param preset [PresetRippleOverlay]
      def update(preset)
        super
        update_position(preset)
      end

      # Update the position
      # @param preset [PresetRippleOverlay]
      def update_position(preset)
        @shader.set_float_uniform('position', preset.position.resolve(preset.resolution, $game_player))
      end
    end
    register_preset(:ripple, PresetRippleOverlay)

    # GodRays overlay
    class PresetGodRaysOverlay < PresetBase
      prepend PresetWithSampleColor

      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_godrays
      end

      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return true
      end

      # Initialize the Godrays preset
      def initialize
        super
        @sample_color = Color.new(153, 102, 26, 128)
        @blend_mode = :screen
      end
    end
    register_preset(:godrays, PresetGodRaysOverlay)
  end
end

vertex_shader = 'graphics/shaders/map_viewport.vert'
Shader.register(:overlay_shader_static_image, 'graphics/shaders/overlay_static_image.frag', vertex_shader)
Shader.register(:overlay_shader_scroll, 'graphics/shaders/overlay_scroll.frag', vertex_shader)
Shader.register(:overlay_shader_water, 'graphics/shaders/overlay_water.frag', vertex_shader)
Shader.register(:overlay_shader_fog, 'graphics/shaders/overlay_fog.frag', vertex_shader)
Shader.register(:overlay_shader_nausea, 'graphics/shaders/overlay_nausea.frag', vertex_shader)
Shader.register(:overlay_shader_ripple, 'graphics/shaders/overlay_ripple.frag', vertex_shader)
Shader.register(:overlay_shader_godrays, 'graphics/shaders/overlay_godrays.frag', vertex_shader)
