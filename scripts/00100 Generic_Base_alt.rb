
module UI
  # Generica base UI for most of the scenes
  class GenericBase < SpriteStack

   DEFAULT_KEYS = %i[Z W X B L R S V G H A T Y F D E C Q]

    # def button_texts=(value)
    #   @button_texts = value
    #   @ctrl.each_with_index do |button, index|
    #     button.visible = true
    #     button.text = value[index] || ""  
    #   end
    # end

    def initialize(viewport, texts = [], keys = DEFAULT_KEYS, hide_background_and_button: false, bar_on_top: false)
      super(viewport)
      @keys = keys
      if bar_on_top
        create_graphics_top
      else
        create_graphics
      end
      self.button_texts = texts
      if hide_background_and_button
        @button_background.visible = false
        @ctrl.each {|button| button.visible = false}
      end
    end

    def create_graphics_top
      create_button_background_top
      create_control_button
    end

    # Hold the wintexts in the interfaces
    def win_text
      @win_text_background ||= add_sprite(0, 170, 'team/Win_Txt').set_z(502)
      @win_text ||= add_text(5, 222, 200, 15, nil.to_s, color: 9)
      @win_text.z = 502
      @win_text
    end

    def show_win_text(text)
      text_sprite = win_text
      text_sprite.visible = true
      text_sprite.text = text
      @win_text_background.visible = true
    end

    # Hide the "win text"
    def hide_win_text
      win_text.visible = false
      @win_text_background.visible = false
    end
    
    # Generic Button used to help the player to know what key he can press
    # Create the control buttons
    def create_control_button
      # tableau des noms d'images de fond pour chaque bouton
      images = %w[
        button_resume1
        button_resume3
        button_resume2
        button_favorite
        button_up
        button_down
        button_x
        button_b
        button_save
        button_x
        button_left
        button_right
        button_sort
        button_favorite
        button_x
        button_b
        button_x
        button_b
      ]

      @ctrl = Array.new(18) do |index|
        ControlButton.new(@viewport, index, images[index])
      end
    end

    # Update the background animation
    def update_background_animation
    end
    
    def create_button_background
      @button_background = add_sprite(0, 168, button_background_filename).set_z(500)
    end

    def create_button_background_top
      @button_background = add_sprite(0, 0, button_background_filename).set_z(500)
    end

    class ControlButton < SpriteStack
      # Array of button coordinates
      COORDINATES = [
        [3,   171],
        [47,  171],
        [91,  171],
        [148, 173],
        [179, 171],
        [208, 172],
        [252, 172],
        [294, 173],
        [75,  173],
        [225, 172],
        [5, 7],
        [156, 7],
        [184, 3],
        [217, 6],
        [247, 7],
        [287, 7],
        [201, 173],
        [229, 173]
      ]

      # Create a new Button
      # @param viewport [Viewport]
      # @param coords_index [Integer] index of the coordinates to use in order to position the button
      # @param key [Symbol] key to show by default
      def initialize(viewport, coords_index, image_name)
        super(viewport, *COORDINATES[coords_index], default_cache: :pokedex)
        @background = add_background(image_name)
        @coords_index = coords_index
        self.pressed = false
        self.z = 501
      end

      # Set the button pressed
      # @param pressed [Boolean] if the button is pressed or not
      def pressed=(pressed)
        #simple opacité quand pressé
        @background.opacity = pressed ? 150 : 255
      end
      alias set_press pressed=


      # Set the text shown by the button
      # @param value [String] text to show
      def text=(value)
      end

      # Set the key shown by the button
      # @param value [Symbol]
      def key=(value)
      end
      private

      # Retrieve the color of the text
      # @param coords_index [Integer] index of the coordinates to use in order to position the button
      # @return [Integer]
      def text_color(coords_index)
        coords_index == 3 ? 21 : 20
      end

      # Retrieve the id of the font used to show the text
      # @return [Integer]
      def text_font
        20
      end
    end
  end
end


