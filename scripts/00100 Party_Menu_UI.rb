module GamePlay
  class Party_Menu < BaseCleanUpdate::FrameBalanced
    # Create the base UI
    def create_base_ui
      @base_ui = UI::GenericBase.new(@viewport, button_texts)
      # Désactiver l’animation du fond
      @base_ui.instance_variable_set(:@background_animation, nil)
      @base_ui.instance_variable_set(:@on_update_background_animation, nil)
      auto_adjust_button
    end

    def button_texts
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "", ""]
    end

    # Create the UI graphics
    def create_graphics
      create_viewport
      create_selected_frame
      create_base_ui
      create_background_sprite
      create_team_buttons
      create_selector
      init_win_text
      Graphics.sort_z
    end

    def update_graphics
      update_selector
      @base_ui.update_background_animation
      @team_buttons.each(&:update_graphics)
      update_selected_gif
    end

    def update_selected_gif
      @team_buttons.each_with_index do |button, i|
        # Donner accès au parent pour vérifier @move
        button.instance_variable_set(:@parent, self)
        
        # Mettre à jour l'état "current" de chaque bouton
        button.current = (i == @index)
        
        if i == @index
          button.selected_gif.visible = true
          button.start_icon_animation
        else
          button.selected_gif.visible = false
          button.stop_icon_animation
        end
      end
    end

    # Crée le sprite de background sous les boutons (version simplifiée)
    def create_background_sprite
      return if @bg
      size = $actors.compact.size
      size = 6 if size > 6
      size = 0 if size < 0
      name = "team/bg_#{size}"
      @bg = Sprite.new(@viewport)
      begin
        @bg.load(name, :interface)
      rescue StandardError
        # Dernier fallback minimal
        @bg.load('team/bg', :interface)
      end
      add_disposable(@bg)
    end

    # Selected frame for the currently selected Pokemon
    def create_selected_frame
      @black_frame = Sprite.new(@viewport)
      @black_frame.z = 600
    end

    # Show the black frame for the currently selected Pokemon
    def show_black_frame
      @black_frame.set_bitmap("team/selected_frame", :interface)
      @black_frame.visible = true
      @black_frame.src_rect.height = FRAME_HEIGHT if FRAME_HEIGHT
    end

        # Hide the black frame for the currently selected Pokemon
    def hide_black_frame
      @black_frame.visible = false
    end

    # Action triggered when A is pressed
    def action_A
      case @mode
      when :menu
        action_A_menu
      else
        $game_system.se_play($data_system.decision_se)
        show_choice
      end
    end

    def get_choice_coordinates(choices)
      choice_height = 16
      height = choices.size * choice_height
      but_x = 420
      but_y = 160
      return but_x, but_y
    end
  end
end


module UI
  # Button that show basic information of a Pokemon
  class TeamButton < SpriteStack
    attr_reader :selected_gif
    attr_reader :icon
    attr_reader :selected
    attr_reader :current

    # List of the Y coordinate of the button (index % 6), relative to the contents definition !
    CoordinatesY = [2, 10, 50, 58, 98, 106]
    # List of the X coordinate of the button (index % 2), relative to the contents definition !
    CoordinatesX = [-14, 114]
    # List of the Y coordinate of the background textures
    TextureBackgroundY = [0, 46, 92, 138, 184]
    # Height of the background texture
    TextureBackgroundHeight = 46

    def create_sprites
      # Show the background
      @background = add_sprite(15, 7, background_name)
      # Chaque colonne fait 126px
      @background.src_rect.width = 126
      @background.src_rect.height = TextureBackgroundHeight

      @selected_gif = create_selected_party_menu_button

      # Show the Pokemon icon sprite
      @icon = add_sprite(37, 24, NO_INITIAL_IMAGE, type: PokemonIconSprite)
      # Show the Pokemon nickname
      add_text(55, 13, 79, 16, :given_name, type: SymText, color: 9)
      # Show the Pokemon gender
      add_sprite(118, 17, NO_INITIAL_IMAGE, type: GenderSprite)
      # Show the Pokemon item hold
      add_sprite(39, 30, 'team/Item', type: HoldSprite)
      # Show the level of the Pokemon
      with_font(20) do
        add_text(32, 38, 61, 16, :level_pokemon_number, type: SymText, color: 9)
      end
      # Show the status of the Pokemon
      add_sprite(119, 46, NO_INITIAL_IMAGE, type: StatusSprite)
      # Show the HP Bar
      @hp = add_custom_sprite(create_hp_bar)
      # add_text(62, 34, 56, 16, :hp_pokemon_number, 2, type: SymText, color: 9)
      # Show the HP text with Power Small Green font
      with_font(20) do
        add_text(62, 34 + 5, 56, 13, :hp_text, 1, type: SymText, color: 9)
      end
      # Show the item button
      @item_sprite = add_sprite(24, 39, 'team/But_Object', 1, 2, type: SpriteSheet)
      # Show the Pokemon item name
      @item_text = add_text(27, 40, 113, 16, :item_name, type: SymText)
      # Hide item by default
      hide_item_name
      # Supprimer le repositionnement manuel - le SpriteStack gère cela automatiquement
    end

    # Create the HP Bar for the pokemon
    # @return [UI::Bar]
    def create_hp_bar
      bar = UI::Bar.new(@viewport, @x + 75, @y + 33, RPG::Cache.interface('team/HPBars'), 48, 2, 0, 0, 3)
      # Define the data source of the HP Bar
      bar.data_source = :hp_rate
      return bar
    end

    # Update the graphics
    def update_graphics
      @icon.update
      @selected_gif.update
      @animation&.update
    end

    # Update the background according to the selected state
    def update_background
      return unless @data

      # Vérifier si on est en mode déplacement (un autre bouton est sélectionné)
      in_move_mode = @parent&.instance_variable_get(:@move) != -1 rescue false

      # Déterminer l'état du bouton
      if @selected
        # Bouton sélectionné pour déplacement (frame 4, peu importe KO ou current)
        frame = 4
      elsif @current && in_move_mode
        # Bouton courant en mode déplacement : utilise l'apparence "selected"
        frame = 4
      elsif @current
        # Bouton sous le curseur (mode normal)
        frame = @data.hp <= 0 ? 3 : 1  # Frame 3 (current KO) ou 1 (current normal)
      else
        # Bouton normal
        frame = @data.hp <= 0 ? 2 : 0  # Frame 2 (normal KO) ou 0 (normal)
      end

      frame_width = 126
      # Seul le premier bouton (index 0) utilise la colonne de gauche
      x_offset = (@index == 0 ? 0 : frame_width)

      @background.src_rect.set(
        x_offset,
        TextureBackgroundY[frame],
        frame_width,
        TextureBackgroundHeight
      )
    end

    
    def start_icon_animation
      return if @animation # Ne pas redémarrer si déjà en cours
      @animation = create_animation
    end

    def stop_icon_animation
      @animation = nil
    end

    def create_selected_party_menu_button
      # Utiliser push comme dans Menu_UI, pas add_sprite
      gif = push(15, 7, nil, type: Selected_party_menu_button)
      gif.visible = false
      gif
    end

    def create_animation
      ya = Yuki::Animation
      
      # Sauvegarder la position de base de l'icône
      @icon_base_y = @icon.y unless @icon_base_y

      # 🚀 Phase d'entrée : descente de 2 px
      entry_down = ya.scalar(0.10, @icon, :y=, @icon_base_y, @icon_base_y + 2)

      # 🌊 Boucle : montée de 3 puis descente de 3
      move_up   = ya.scalar(0.15, @icon, :y=, @icon_base_y + 2, @icon_base_y - 1)  # +2 -> -1 = 3 px vers le haut
      move_down = ya.scalar(0.15, @icon, :y=, @icon_base_y - 1, @icon_base_y + 2)  # redescend de 3 px

      # Chaînage
      entry_down.play_before(move_up)
      move_up.play_before(move_down)

      # Créer l'animation principale
      animation = ya.timed_loop_animation(0.30) # 0.15 + 0.15 pour la boucle
      animation.parallel_add(entry_down)

      animation.start
      return animation
    end

    # Set the selected state of the sprite
    # @param v [Boolean]
    def selected=(v)
      @selected = v
      update_background
    end

    # Set if this button is the current one (under cursor)
    # @param v [Boolean]
    def current=(v)
      @current = v
      update_background
    end
  end
end


module GamePlay
  class Party_Menu
    # rubocop:disable Naming/MethodName
    # Array of actions to do according to the pressed button
    Actions = %i[NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA NA action_return_map action_B]

    # Return diretly to map 
    def action_return_map
      play_cancel_se
      # On nettoie toutes les scènes en cours
      $scene = Scene_Map.new
      @running = false
    end

    def NA 
      # no action method
    end

    def action_B
      $game_system.se_play($data_system.cancel_se)
      @running = false
    end
  end
end


module UI
  class Selected_party_menu_button < Sprite
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'team', 'selected_button.gif')
      @gif_reader = Yuki::GifReader.new(path)
      self.bitmap = Texture.new(@gif_reader.width, @gif_reader.height)
      @gif_reader.update(self.bitmap)
      set_origin(0,0)

      # Blink variables
      @blink_counter = 0
      @blink_phase = :off
      @blink_active = false
    end

    def start_blink(&on_end)
      @blink_counter = 0
      @blink_phase = :off
      @blink_active = true
      @on_blink_end = on_end
    end

    def update
      @gif_reader&.update(bitmap)

      return unless @blink_active

      @blink_counter += 1
      case @blink_counter
      when 1..3
        self.visible = false
      when 4..6
        self.visible = true
      when 7..9
        self.visible = false
      when 10..12
        self.visible = true
      when 13..14
        self.visible = false  # ← dernière phase, invisible
      else
        @blink_active = false
        # Assurer qu'on reste invisible à la fin
        self.visible = false
        # 🔥 Exécuter le callback si défini
        @on_blink_end&.call
        @on_blink_end = nil
      end
    end
  end
end

