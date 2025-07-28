# What is the Map Overlay Feature?

> [!NOTE]  
> To read this file the intended way, open this file using Visual Studio Code (VSCode) and type CTRL+K, then V.  
> It will open the preview of this file.  
> You can also read it on the official GitLab repository of PSDK.  
> Enjoy your reading!

A **Map Overlay** is a configurable shader that is visible in the overworld. Tired of plain tone blending? Now your game can show a complex underwater effect, sunrays coming from above, or a radar wave emanating from a tile you specify!

Despite relying on shaders, Map Overlays can be started, stopped, and manipulated in a **user-friendly** way, directly **from event commands**, with no more coding knowledge than the rest of PSDK. Multiple **presets** have already been implemented, so you can [start testing the feature right away](#basics), and you've also been given the ability to freely change their settings.

You can also create your very own Map Overlay presets if you're feeling adventurous: see [Create your own Map Overlay](#create-your-own-map-overlay) for details. The only limits of Map Overlays are your patience and imagination!

## Prerequisites

For the feature to work as intended, make sure to add the default map overlay shader files to your `graphics/shaders/` folder, as well as `noise_texture.png` and `water_color_gradient.png` in `graphics/fogs/`.

## Basics

In the following tutorial, we will explain the basics of manipulating an existing Map Overlay.

### Existing presets

At the time of writing, the available presets are:

- `:static_image`
- `:scroll`
- `:water`
- `:fog`
- `:nausea`
- `:ripple`
- `:godrays`

Their corresponding shader files are named `overlay_<preset>.frag` and registered as `:overlay_shader_<preset>`. For example, the `:water` preset corresponds to `overlay_water.frag`, which is registered as `:overlay_shader_water`. If you are missing the shader file, you will see an error in the console when trying to start the shader.

For reference, all Interpreter commands of the Map Overlay are in `160 Interpreter_Overlay.rb`.

### Starting a Map Overlay Preset

To start a Map Overlay, run the Interpreter command `start_overlay`. For example: `start_overlay(:water)`. This can be done from an event directly, or in the console: `S.MI.start_overlay(:water)`.

```Ruby
start_overlay(:water)
```

### Stopping the Map Overlay Feature

Run `stop_overlay` to restore the default simple tint shader on the map.

### Pausing or Unpausing Shader Updates

You can pause or unpause the time update process of your Map Overlay with the preset attribute `paused`.

```Ruby
# Pause
current_overlay_preset.paused = true
# Unpause
current_overlay_preset.paused = false
```

The paused attribute default is set by the return value of preset method: `has_animation?`. If this method state the preset has no animation (`false`), then the `paused` attribute is `true` by default (and vice versa). You can monkey patch the `has_animation?` method.

### Blend Modes

At the time of writing of this file, the available blend modes are the following:

- `:normal`
- `:add`
- `:subtract`
- `:multiply`
- `:overlay`
- `:screen`

To set the blend mode, use `current_overlay_preset.blend_mode`. The argument should be the blend mode of your choice.

### Tilemap to UV Conversion

Some shader (such as ripple) needs Tile to UV Conversion. For that the attribute `position` takes an instance of `PFM::MapOverlay::UVResolver`.

This value can be set to a variety of UVResolver:

```ruby
# Set position to game player coordinates
current_overlay_preset.position = PFM::MapOverlay::UVResolver.new(:game_player)
# Set position to a specific map coordinate (x=15, y=33)
current_overlay_preset.position = PFM::MapOverlay::UVResolver.new([15, 33])
```

Note: UVResolver currently only support tile coordinates. It could be upgraded with other kind of coordinates.

## Create Your Own Map Overlay

Perhaps you have a very specific idea that's not covered by existing presets. Of course, you can create your very own Map Overlay! You could even share it with the community as a PSDK Plugin later.

In the following tutorial, we will learn how to create your own custom Map Overlay. We will use `:preset` as a placeholder for the symbol of your new Map Overlay; swap it out for your own custom symbol in your monkey-patch.

Please see `/scripts/HOW_TO_CREATE_A_CUSTOM_SCRIPT.md` for details on monkey-patching PSDK. Never change the base code of PSDK yourself unless you're contributing!

### Registering Your Preset and Shader File

1. Create a new .rb file in your `/scripts/` folder containing the following:

```Ruby
# /scripts/00001 MyMapOverlay.rb
module PFM
  class MapOverlay
    # Static image overlay
    class PresetCustom < PresetBase
      # <= Put the custom preset attributes here

      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_preset # <= Name of the shader we will register in step 2
      end

      def initialize
        super
        # <= Put the custom preset attributes initialization here
      end

      # Update the preset in UI space
      # @param preset [PresetCustom]
      def update(preset)
        super(preset)
        # <= Call the preset attribute update functions here (eg. update_extra_texture(preset))
      end

      # <= Define the custom preset update functions here

      def dispose
        super
        # <= Add the disposable resource dispose call here
      end
    end

    register_preset(:preset, PresetCustom)
  end
end
```

2. Create and register your shader file (just create a blank .frag file for now):

```Ruby
Shader.register(:overlay_shader_preset, 'graphics/shaders/overlay_preset.frag', 'graphics/shaders/map_viewport.vert')
# Should go outside of the module
```

See [Creating your own fragment shader](#creating-your-own-fragment-shader) for details.

#### Optional Step

If your Map Overlay requires regular updates (changes over time), add the following code to your preset class:

```ruby
      # Tell if the preset has an animation
      # @return [Boolean]
      def has_animation?
        return true
      end
```

### Setting your Preset's attributes

You've registered your Map Overlay's symbol and shader, but PSDK doesn't know what parameters they need. To remedy that, you have to define the preset's initial attributes in its `initialize` method.

Once the attributes are defined, you need to define the UI update methods to handle changes in the attributes. This way the shader will know the most current preset attribute value on next update.

Example with the Ripple Effect:

```Ruby
    # Ripple overlay
    class PresetRippleOverlay < PresetBase
      # <= Here come the sample_color and position attribute accessor

      # Get or set the sample_color
      # @return [Color]
      attr_accessor :sample_color

      # Get or set the position
      # @return [PFM::MapOverlay::UVResolver]
      attr_accessor :position

      private

      def initialize
        super
        # <= Here we define the sample_color and position default values
        # @note You can overwrite default attribute from parent (eg. set @blend_mode to non 0).
        @sample_color = Color.new(0, 26, 26, 128)
        @position = UVResolver.new(:game_player)
      end

      # Update the preset in UI space
      # @param preset [PresetRippleOverlay]
      def update(preset)
        super(preset)
        # <= Here we call the update method for each attributes
        update_position(preset)
        update_sample_color(preset)
      end

      # Update color_gradient texture in UI space
      # @param preset [PresetRippleOverlay]
      def update_sample_color(preset)
        # <= Here we check the change between preset and current value
        return if @sample_color == preset.sample_color

        # <= Here we assign the sample_color to shader and store the current value
        @shader.set_float_uniform('sample_color', @sample_color = preset.sample_color.dup)
      end

      # Update the position
      # @param preset [PresetRippleOverlay]
      def update_position(preset)
        # <= Here we do always set the position attribute in the shader since it's a dynamic value (depends on player position)
        @shader.set_float_uniform('position', preset.position.resolve(preset.resolution, $game_player))
      end
    end
```

You may be able to manually change the attributes value using `current_overlay_preset`. (See [Pausing or Unpausing Shader Updates](#pausing-or-unpausing-shader-updates))

#### Final Look

```Ruby
# Don't forget to swap "preset" with your own symbol!
Shader.register(:overlay_shader_preset, 'graphics/shaders/overlay_preset.frag', 'graphics/shaders/map_viewport.vert')

module PFM
  class MapOverlay
    # Static image overlay
    class PresetCustom < PresetBase
      # Get or set effect value
      # @return [Integer]
      attr_accessor :effect

      private

      # Name of the shader to load
      # @return [Symbol]
      def shader_name
        :overlay_shader_preset
      end

      def initialize
        super
        @effect = 0
      end

      # Update the preset in UI space
      # @param preset [PresetCustom]
      def update(preset)
        super(preset)
        update_effect(preset)
      end

      # Update the preset effect in UI space
      # @param preset [PresetCustom]
      def update_effect(preset)
        return if @effect == preset.effect

        @shader.set_int_uniform('effect', @effect = preset.effect)
      end
    end

    register_preset(:preset, PresetCustom)
  end
end
```

That's it for the Ruby side. Next up: **the fragment shader**!

### Creating Your Own Fragment Shader

The shaders provided with this feature contain plenty of examples and helper functions, removing the need for you to come up with everything on your own. You are free to copy anything in them to make your own fragment shader.

Nevertheless, it is better to have a basic understanding of shaders before touching them. Here are some resources:

[A 5 minutes tutorial video that explains shaders in simple terms by PlayWithFurcifer on YouTube](https://www.youtube.com/watch?v=eU-F-xuEo7s&list=PLIPN1rqO-3eHrOQ8BpTtelpq46TF_yFdk&index=18)

[The Book of Shaders, a step-by-step tutorial (in depth)](https://thebookofshaders.com/)

#### Requirements

- A Map Overlay shader needs to be compatible with PSDK's color_process and tone_process

- Keeping compatibility with the Map Overlay's blend modes is strongly recommended

- Your new shader should _preferably_ be named after your preset: `overlay_preset.frag`

If not starting from an existing preset's shader, you can use the Minimum compatibility Map Overlay shader file below.

#### Minimum compatibility Map Overlay shader

_As helper functions have been removed from the minimum file, please refer to existing presets' files for them._

<details>
<summary><b>Minimum Map Overlay GLSL File</b></summary>

```glsl
//uniform keeping track of the blend mode
// 0: normal (mix)
// 1: add
// 2: subtract
// 3: multiply
// 4: overlay
// 5: screen
uniform int blend_mode = 0;

//// compatibility with other SpritesetMap shaders

const vec3 lumaF = vec3(.299, .587, .114);

uniform vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 tone = vec4(0.0, 0.0, 0.0, 0.0);

////

//uniform keeping track of base texture
uniform sampler2D texture;
//uniform keeping track of the time variable
uniform float time;
//uniform keeping track of the opacity variable
uniform float opacity = 1.0;

//constant keeping track of a small number for comparison purposes
const float SMALL_NUMBER = 0.0001;

//function to compute the overlay blend mode effect
vec4 overlay_blend_mode(vec4 base, vec4 blend1)
{
  vec4 limit = step(0.5, base);
  return mix(2.0 * base * blend1, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend1), limit);
}

// function to compute the screen blend mode effect
vec4 screen(vec4 base, vec4 blend)
{
  return 1.0 - (1.0 - base) * (1.0 - blend);
}

// account for opacity in blend modes
vec3 blend(vec3 frag, vec3 overlay, float overlay_opacity)
{
  float base_opacity = 1.0 - overlay_opacity;
  return step(SMALL_NUMBER, float(blend_mode==0)) * mix(frag, overlay, overlay_opacity)
      +	 step(SMALL_NUMBER, float(blend_mode==1)) * (frag * base_opacity + (overlay + frag) * overlay_opacity)
      +	 step(SMALL_NUMBER, float(blend_mode==2)) * (frag * base_opacity + (overlay - frag) * overlay_opacity)
      +	 step(SMALL_NUMBER, float(blend_mode==3)) * (frag * base_opacity + (overlay * frag) * overlay_opacity)
      +	 step(SMALL_NUMBER, float(blend_mode==4)) * overlay_blend_mode(vec4(frag, 1.0),vec4(overlay.rgb, overlay_opacity)).rgb
      +	 step(SMALL_NUMBER, float(blend_mode==5)) * screen(vec4(frag, 1.0),vec4(overlay.rgb, overlay_opacity)).rgb;
}

// account for blend mode
// 0: normal (mix)
// 1: add
// 2: subtract
// 3: multiply
// 4: overlay
vec4 account_for_blend_mode(vec4 frag, vec4 overlay)
{
  float overlay_opacity = opacity * overlay.a;
  return vec4(blend(frag.rgb,overlay.rgb,overlay_opacity),frag.a);
}

// Your preset's code goes here
vec4 preset(vec2 pixPos)
{
  return texture2D(texture, pixPos);
}

//main function where everything happens
void main() {
  //load the base texture
  vec4 frag = texture2D(texture, gl_TexCoord[0].xy);

  //overlay presets
  vec4 overlay = preset(gl_TexCoord[1].xy);

  //set the final color
  frag = account_for_blend_mode(frag,overlay);

  ////compability with color_process
  frag.rgb = mix(frag.rgb, color.rgb, color.a);

  ////compability with tone_process
  float luma = dot(frag.rgb, lumaF);
  frag.rgb = mix(frag.rgb, vec3(luma), tone.a);
  frag.rgb += tone.rgb;
  ////

  gl_FragColor = frag;

}
```

</details>
