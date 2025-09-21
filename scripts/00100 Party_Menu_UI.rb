    
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

    # Create the UI graphics
    def create_graphics
      create_viewport
      crate_selected_frame
      create_base_ui
      create_team_buttons
      create_selector
      init_win_text
      Graphics.sort_z
    end

    def crate_selected_frame
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
  end
end




module UI
  # Button that show basic information of a Pokemon
  class TeamButton < SpriteStack

    # List of the Y coordinate of the button (index % 6), relative to the contents definition !
    CoordinatesY = [0, 24, 64, 88, 128, 152]
    # List of the X coordinate of the button (index % 2), relative to the contents definition !
    CoordinatesX = [0, 160]
    # List of the Y coordinate of the background textures
    TextureBackgroundY = [0, 47, 94, 141, 188]
    # Height of the background texture
    TextureBackgroundHeight = 46

    def create_sprites
      # Show the background
      @background = add_sprite(15, 7, background_name)
      # Chaque colonne fait 126px
      @background.src_rect.width = 126
      @background.src_rect.height = TextureBackgroundHeight

      # Show the Pokemon icon sprite
      @icon = add_sprite(32, 24, NO_INITIAL_IMAGE, type: PokemonIconSprite)
      # Show the Pokemon nickname
      add_text(50, 17, 79, 16, :given_name, type: SymText, color: 9)
      # Show the Pokemon gender
      add_sprite(132, 20, NO_INITIAL_IMAGE, type: GenderSprite)
      # Show the Pokemon item hold
      add_sprite(35, 31, 'team/Item', type: HoldSprite)
      # Show the level of the Pokemon
      add_text(38, 38, 61, 16, :level_pokemon_number, type: SymText, color: 9)
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
    end

    def update_background
      # Détermination de la frame
      frame = if @data.hp <= 0
                @selected ? 3 : 2 # KO
              else
                @selected ? 1 : 0 # Normal
              end

      # Exemple si tu veux gérer ton état bonus :
      # frame = 4 if condition_bonus

      frame_width = 126
      x_offset = (@index == 0 ? 0 : frame_width)

      @background.src_rect.set(
        x_offset,
        TextureBackgroundY[frame],
        frame_width,
        TextureBackgroundHeight
      )
    end
  end
end