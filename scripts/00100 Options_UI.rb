module UI
  module Options
    # Class that shows the option description
    class Description < SpriteStack
      # Create a new InfoWide
      # @param viewport [Viewport]
      def initialize(viewport)
        super(viewport, 0, 0)
        create_sprites
      end

      private

      def create_sprites
        @description = add_background('options/description')
        @description.zoom_x = 1.25
        @description.zoom_y = 1.25
        @description.x = 0
        @description.y = 150 # au lieu de set_origin
        # @name = add_text(3, 19, 0, 13, :name, type: SymText, color: 25)
        @descr = add_text(10, 158, 310, 20, :description, type: SymMultilineText, color: 33, sizeid: 7)
      end
    end
  end
end



module UI
  module Options
    # Button UI element
    class Button < SpriteStack

      attr_reader :backgroundgif

      # Offset Y of each options
      OPTION_OFFSET_Y = 30
      # Base X of each options
      OPTION_BASE_X = 0
      # Offset X of each options
      OPTION_OFFSET_X = 0

      def initialize(viewport, index, option)
        super(viewport, OPTION_BASE_X, OPTION_OFFSET_Y * index)
        @option = option
        @value = option.current_value

        # Fond du bouton
        @option_background = add_background('options/option')
        @option_background.zoom_x = 1.25
        @option_background.zoom_y = 1.25

        # Initialisation du gif
        init_sprite

        # Nom du bouton
        @option_name = add_text(10, 5, 0, 16, @option.name, color: 30, sizeid: 7)

        # ✅ Tous les textes des valeurs
        # Dans initialize
        @value_texts = []
        @value_markers = []
        # Dans UI::Options::Button#initialize
        spacing = case @option.values_text.size
                  when 2 then 86 # espacement plus large si 2 valeurs
                  when 3 then 55 # (optionnel : tu peux ajuster à la main)
                  else 42       # par défaut (ex: résolution à 4 valeurs)
                  end

        base_x = 155 # point de départ commun pour tous

        @option.values_text.each_with_index do |val, i|
          x = base_x + i * spacing
          txt = add_text(x, 5, 40, 16, val, 0, color: 30, sizeid: 7)
          @value_texts << txt

          marker = push(x - 9, 6, nil, type: ValueMarker)
          marker.zoom_x = 1.25
          marker.zoom_y = 1.25
          @value_markers << marker
        end

      end

      def value=(new_value)
        @value = new_value
        @value_texts.each_with_index do |txt, i|
        end

      end

      def reload_texts
        # Met à jour le nom du bouton
        @option_name.text = @option.name

        # Met à jour toutes les valeurs affichées
        @value_texts.each_with_index do |txt, i|
          txt.text = @option.values_text[i]
        end
      end




      def current_option
        @options[@order[@index]]
      end
      
      def update_graphics
        @backgroundgif.update if @backgroundgif.visible
        @value_markers.each(&:update) # on ne filtre pas, update se gère tout seul
      end




      
      def init_sprite
        @backgroundgif = create_background_gif
        @backgroundgif.zoom_x = 1.25
        @backgroundgif.zoom_y = 1.25
        @backgroundgif.visible = false
      end

      def create_background_gif
        push(0, 0, nil, type: SelectedGifSprite)
      end


      def current_value_index
        @option.values.index(@option.current_value) || 0
      end

      def set_selected(selected)
        current_index = current_value_index

        if selected
          @option_name.load_color(32)
          @value_texts.each_with_index do |txt, i|
            if i == current_index
              txt.load_color(32)
              @value_markers[i].set_state(4) # valeur sélectionnée dans bouton sélectionné
            else
              txt.load_color(31)
              @value_markers[i].set_state(3) # gif pour les non-sélectionnées dans bouton sélectionné
            end
          end
        else
          @option_name.load_color(30)
          @value_texts.each_with_index do |txt, i|
            if i == current_index
              txt.load_color(30)
              @value_markers[i].set_state(2) # valeur retenue dans bouton non sélectionné
            else
              txt.load_color(29)
              @value_markers[i].set_state(1) # valeur pas retenue, bouton pas sélectionné
            end
          end
        end
      end
    end
  end
end


module UI
  # Class that shows a static background gif (ignores Pokémon data)
  class SelectedGifSprite < Sprite
    # Create the gif background sprite
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'options', 'option_selected.gif')
      @gif_reader = Yuki::GifReader.new(path)
      self.bitmap = Texture.new(@gif_reader.width, @gif_reader.height)
      @gif_reader.update(self.bitmap)
      set_origin(0,0)
    end

    # Update the gif animation
    def update
      @gif_reader&.update(bitmap)
    end
  end
end

module GamePlay
  # Options scene
  class Options

    def create_graphics
      create_viewport
      create_base_ui
      create_description
      create_buttons
      create_frame
      create_header
      Graphics.sort_z
    end

    def create_header
      @header = UI::Options::Header.new(@viewport)
    end

    # Update the options graphics
    def update_graphics
      UI::Options::ValueMarker.update_shared
      @buttons.each_with_index do |btn, i|
        is_selected = (i == @index)
        btn.backgroundgif.visible = is_selected
        btn.set_selected(is_selected)
        btn.update_graphics
      end
    end



    def create_viewport
      @viewport = Viewport.create(0, 0, Graphics.width, Graphics.height, 10_000)
      @button_viewport = Viewport.create(0, 30, Graphics.width, Graphics.height, 10_000)
    end

    def create_buttons
      @buttons = []

      # 1. Vitesse du texte
      if @options[:message_speed]
        @text_speed_button = UI::Options::Button.new(@button_viewport, 0, @options[:message_speed])
        @buttons << @text_speed_button
      end

      # 2. Animation combat
      if @options[:battle_animation]
        @battle_animation_button = UI::Options::Button.new(@button_viewport, 1, @options[:battle_animation])
        @buttons << @battle_animation_button
      end

      # 3. Style de combat
      if @options[:battle_style]
        @battle_style_button = UI::Options::Button.new(@button_viewport, 2, @options[:battle_style])
        @buttons << @battle_style_button
      end

      # 4. Résolution
      if @options[:screen_scale]
        @resolution_button = UI::Options::Button.new(@button_viewport, 3, @options[:screen_scale])
        @buttons << @resolution_button
      end

      @arrow = UI::Options::Arrow.new(@button_viewport)
      @arrow.oy -= (@buttons.first&.stack&.first&.height || 0) / 2
      @max_index = @buttons.size - 1
    end

    def update_input_option_value
      new_value = nil
      index = current_option.values.index(current_option.current_value)

      if Input.repeat?(:RIGHT)
        # uniquement si pas déjà au max
        if index < current_option.values.size - 1
          new_value = current_option.values[index + 1]
        end
      elsif Input.repeat?(:LEFT)
        # uniquement si pas déjà au min
        if index > 0
          new_value = current_option.values[index - 1]
        end
      end

      return true if new_value.nil?

      if new_value == current_option.current_value
        play_buzzer_se
      else
        play_cursor_se
        @buttons[@index].value = new_value
        current_option.update_value(new_value)
        reload_texts if @options.key(@buttons[@index].option) == :language
      end
      return false
    end

  end
end


module UI
  module Options
    # Conteneur pour les éléments globaux (titre, etc.)
    class Header < SpriteStack
      def initialize(viewport)
        super(viewport, 0, 0)
        create_sprites
      end

      def create_sprites
        # Exemple : un texte titre
        @title = add_text(53, 0, 200, 24, "OPTIONS", color: 10, sizeid: 7)
      end
    end
  end
end

module UI
  module Options
    class ValueMarker < Sprite
      # GifReader global partagé entre toutes les instances
      @@shared_gif_reader = nil
      @@shared_bitmap = nil

      def initialize(viewport)
        super(viewport)
        self.x = 0
        self.y = 0
        @state = nil
        set_state(2) # état par défaut
      end

      def set_state(state)
        return if @state == state
        @state = state

        case state
        when 1
          self.bitmap = RPG::Cache.interface('options/value_state1')
        when 2
          # Initialise le GifReader partagé une seule fois
          unless @@shared_gif_reader
            path = File.join('graphics', 'interface', 'options', 'value_state3.gif')
            @@shared_gif_reader = Yuki::GifReader.new(path)
            @@shared_bitmap = Texture.new(@@shared_gif_reader.width, @@shared_gif_reader.height)
            @@shared_gif_reader.update(@@shared_bitmap)
          end
          self.bitmap = @@shared_bitmap
        when 3
          self.bitmap = RPG::Cache.interface('options/value_state4')
        when 4
          self.bitmap = RPG::Cache.interface('options/value_state2')
        end
      end

      def self.update_shared
        # Met à jour l’animation du GIF partagé
        @@shared_gif_reader&.update(@@shared_bitmap)
      end

      def update
        # Ne fait rien, tout est géré par update_shared
      end
    end
  end
end



module GamePlay
  # Options scene
  class Options
    include OptionsMixin
    # List of action the mouse can perform with ctrl button
    ACTIONS = %i[save_options save_options save_options save_options]
    # Maximum number of button shown in the UI for options (used to calculate arrow position)
    MAX_BUTTON_SHOWN = 4

    # Create a new Options scene
    def initialize
      super
      # @type [Hash{Symbol => Helper}]
      @options = {}
      @order = Configs.game_options.order
      @order.delete(:language) if Configs.language.choosable_language_code.none?
      @order.delete_if { |sym| !PREDEFINED_OPTIONS[sym] }
      load_options
      @modified_options = []
      @index = -1
      @max_index = 0
      @options_copy = $options.clone
    end
  end
end


