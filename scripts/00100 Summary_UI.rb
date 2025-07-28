


module UI
  # Generica base UI for most of the scenes (moving background)
  class GenericBase < SpriteStack
    def create_background_animation
      ya = Yuki::Animation
      duration = 2
      @background_animation = ya.timed_loop_animation(duration)
      @background_animation.play_before(ya.shift(duration, @background, 0, 0, 40, 40))
      @on_update_background_animation = proc do
        @background_animation.start
        @on_update_background_animation = nil
      end
    end
  end
end

module UI
  # UI part displaying the "Memo" of the Pokemon in the Summary
  class Summary_Memo < SpriteStack
    def create_background
      push(0, 0, 'summary/memo')
    end
  end
end


module UI
  # UI part displaying the "Memo" of the Pokemon in the Summary
  class Summary_Memo < SpriteStack
    # Return the color id
    # @return [Integer]
    def color_id
      $trainer.playing_girl ? 2 : 1
    end

    def fix_level_text_position
      @level_text.x = 205
    end

    # Initialize the Memo part
    def init_memo
      texts = text_file_get(27)
      with_surface(114, 19, 95) do
        # --- Static part ---
        text0 = no_egg add_text(23, 12, 5, 16, texts[0], 0, 0, sizeid: 4, color: 9) # NoPokedex
        

        text2 = add_text(23, 31, 92, 16, texts[2], 0, 0, sizeid: 4, color: 9) # Nom
        text2.bold = true

        text3 = no_egg add_text(23, 50, 92, 16, texts[3], 0, 0, sizeid: 4, color: 9) # Type
        text3.bold = true

        text8 = no_egg add_text(23, 70, 92, 16, texts[8], 0, 0, sizeid: 4, color: 9) # DO
        text8.bold = true

        text9 = no_egg add_text(23, 91, 92, 16, texts[9], 0, 0, sizeid: 4, color: 9) # Numero id

        text10 = no_egg add_text(23, 112, 9, 16, texts[10], 0, 0, sizeid: 4, color: 9) # Pt exp
        text10.bold = true

        text12 = no_egg add_text(23, 151, 92, 16, texts[12], 0, 0, sizeid: 4, color: 9) # Next lvl
        text12.bold = true

        no_egg add_text(205, 172, 92, 16, text_get(23, 7), color: 7) # Objet
        @level_text = no_egg(add_text(0, 21, 92, 16, texts[29], 0, 0, sizeid: 4)) # Level

        
        # --- Data part ---
        with_font(20) { no_egg add_text(11, 125, 56, nil, 'EXP') }
        add_text(102, 31, 92, 16, :name, type: SymText, sizeid: 4, color: 7) # name
        add_text(102, 12, 92, 16, :id_text, type: SymText, sizeid: 4) #No pokedex
        add_text(102, 131, 92, 16, :exp_text, type: SymText, sizeid: 4, color: 7) # exp
        add_text(102, 170, 92, 16, :exp_remaining_text, type: SymText, sizeid: 4, color: 7) # exp remaining
        @level_value = no_egg(add_text(235, 21, 92, 16, :level_text, type: SymText, sizeid: 4, color: 7)) # level
        no_egg add_text(102, 91, 92, 16, :trainer_id_text, type: SymText, sizeid: 4, color: 7) # trainer_id
        no_egg add_text(200, 190, 92, 16, :item_name, type: SymText, sizeid: 4, color: 7) #item name
      end
      text13 = no_egg add_text(102, 72, 92, 16, :trainer_name, type: SymText, sizeid: 4, color: color_id) # trainer name
      text13.bold = true

      no_egg push(102, 55, nil, type: Type1Sprite)
      no_egg push(140, 55 + 0, nil, type: Type2Sprite)
    end
  end
end

module UI
  # UI part displaying the "Memo" of the Pokemon in the Summary
  class Summary_Memo < SpriteStack
    # Define the pokemon shown by this UI
    # @param pokemon [PFM::Pokemon]
    def data=(pokemon)
      if (self.visible = !pokemon.nil?)
        super
        @invisible_if_egg.each { |sprite| sprite.visible = false } if pokemon.egg?
        fix_level_text_position
        #load_text_info(pokemon)
      end
    end
  end
end


module UI
  # UI part displaying the generic information of the Pokemon in the Summary
  class Summary_Top < SpriteStack
    # @return [SymText]
    def create_name_text
      add_text(220, 4, 100, 16, :given_name, type: SymText, color: 7)
    end

    # @return [GenderSprite]
    def create_gender
      push(340, 10, nil, type: GenderSprite)
    end

        # @return [Sprite]
    def create_ball
      push(210, 12, nil, ox: 16, oy: 16)
    end
  end
end

module UI
  # UI part displaying the generic information of the Pokemon in the Summary
  class Summary_Top < SpriteStack
    attr_reader :pokemon_sprite # 👈 expose le face sprite
    attr_reader :pokemon_back_sprite

    def init_sprite
      @pokemon_sprite = create_sprite
      @name = create_name_text
      @gender = create_gender
      @item = create_item
      @ball = create_ball
      @star = create_star
      @pokerus = create_pokerus
      create_status
    end
        # Update the graphics
    def update_graphics
      if @pokemon_sprite.respond_to?(:visible) && @pokemon_sprite.visible
        @pokemon_sprite.update
      end

      if @pokemon_back_sprite.respond_to?(:visible) && @pokemon_back_sprite.visible
        @pokemon_back_sprite.update
      end
    end



    # @return [PokemonFaceSprite]
    def create_sprite
      @pokemon_sprite = push(220, 150, nil, type: PokemonFaceSprite)
      @pokemon_sprite.zoom_x = 1.28
      @pokemon_sprite.zoom_y = 1.28
      return @pokemon_sprite
    end
    def create_back_sprite
      @pokemon_back_sprite = push(220, 150, nil, type: PokemonBackSprite)
      @pokemon_back_sprite.zoom_x = 1.28
      @pokemon_back_sprite.zoom_y = 1.28
      @pokemon_back_sprite.visible = false
      return @pokemon_back_sprite
    end
    def create_back_sprite_lazily
      return if @pokemon_back_sprite

      @pokemon_back_sprite = push(220, 150, nil, type: PokemonBackSprite)
      @pokemon_back_sprite.zoom_x = 1.28
      @pokemon_back_sprite.zoom_y = 1.28
      @pokemon_back_sprite.data = @data if @data # 👈 injecte le Pokémon
      @pokemon_back_sprite.visible = true
    end


  end
end



module UI
  # UI part displaying the "Memo" of the Pokemon in the Summary
  class Summary_Memo < SpriteStack

    def create_background
      # push(0, 0, 'summary/memo')
    end


    # Update the graphics
    def update_graphics
      @backgroundgif.update
    end
    
    private

    def init_sprite
      @backgroundgif = create_background_gif
      create_background
      init_memo
      @text_info = create_text_info
      no_egg @exp_container = push(30, 129, RPG::Cache.interface('exp_bar'))
      no_egg @exp_bar = push_sprite(create_exp_bar)
      @exp_bar.data_source = :exp_rate
    end

    def create_background_gif 
      push(0, 0, nil, type: BackgroundGifSprite)
    end
  end
end



module UI
  # Class that shows a static background gif (ignores Pokémon data)
  class BackgroundGifSprite < Sprite
    # Create the gif background sprite
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'my_background.gif')
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
  class Summary
    # Update the graphics
    def update_graphics
      @base_ui.update_background_animation
      @top.update_graphics
      @memo.update_graphics
    end
  end
end

module GamePlay
  # Scene displaying the Summary of a Pokemon
  class Summary < BaseCleanUpdate::FrameBalanced

    def initialize(pokemon, mode = :view, party = [pokemon], extend_data = nil)
      super()
      # @type [PFM::Pokemon]
      @pokemon = pokemon
      @mode = mode
      @party = party
      @index = mode == :skill ? 2 : 0
      @party_index = party.index(pokemon).to_i
      @skill_selected = -1
      @skill_index = -1
      @selecting_move = false
      @extend_data = extend_data
    end

    # Create the various UI
    def create_uis
      @top = UI::Summary_Top.new(@viewport)
      @top.data = @pokemon
      @uis = [
        @memo = UI::Summary_Memo.new(@viewport),
        UI::Summary_Stat.new(@viewport),
        UI::Summary_Skills.new(@viewport)
      ]
      update_sprite_visibility
    end

    def mouse_click_sprite
      return unless @top.pokemon_sprite&.mouse_in? && Mouse.trigger?(:LEFT)

      $game_system.se_play($data_system.decision_se)
      @showing_back_sprite = !@showing_back_sprite
      update_sprite_visibility
    end

    def update_sprite_visibility
      if @showing_back_sprite
        # Création du back sprite si pas encore fait
        @top.create_back_sprite_lazily unless @top.pokemon_back_sprite

        @top.pokemon_sprite.visible = false
        @top.pokemon_back_sprite.visible = true
      else
        @top.pokemon_sprite.visible = true
        @top.pokemon_back_sprite.visible = false if @top.pokemon_back_sprite
      end
    end


    def update_inputs
      mouse_click_sprite
      return update_inputs_skill if @mode == :skill
      return update_inputs_view if @mode == :view
      @running = false if Input.trigger?(:B)
      return true
    end
  end
end




module GamePlay
  class Summary
    def update_inputs_basic(allow_up_down = true)
      # On autorise la navigation haut/bas uniquement si on a plus d'un Pokémon
      allow_up_down &&= @party.size > 1

      # Changement d’UI (pas possible si c’est un œuf ou si on déplace une capacité)
      if !@pokemon.egg? && !@selecting_move
        if Input.trigger?(:LEFT) && @index > 0
          @index -= 1
          update_ui_visibility
          return true
        elsif Input.trigger?(:RIGHT) && @index < LAST_STATE
          @index += 1
          update_ui_visibility
          return true
        end
      end

      # Changement de Pokémon avec flèches haut/bas
      if allow_up_down && index_changed(:@party_index, :UP, :DOWN, @party.size - 1)
        update_switch_pokemon
        return true
      end

      # Annulation avec B
      if Input.trigger?(:B)
        $game_system.se_play($data_system.cancel_se)
        @skill_selected = -1
        @running = false
      end

      if Input.trigger?(:Y)
        $game_system.se_play($data_system.cancel_se)
        # On arrête complètement la scène et on signale au menu qu’on ne veut pas y retourner
        @force_exit_to_map = true
        @running = false
        return true
      end

      return false
    end

  end
end


