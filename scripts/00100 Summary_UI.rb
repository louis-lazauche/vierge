#-----------------------------------------------------------------------------
#                       BACKGROUND ANIMATION AND GIF
#-----------------------------------------------------------------------------



module UI
  class Summary_Memo < SpriteStack
    # Update the graphics
    def update_graphics
      @backgroundgif.update
    end
    
    private

    def init_sprite
      @backgroundgif = create_background_gif
      init_memo
      @text_info = create_text_info
      no_egg @exp_container = push(99, 194, RPG::Cache.interface('exp_bar'))
      no_egg @exp_bar = push_sprite(create_exp_bar)
      @exp_bar.data_source = :exp_rate
    end

    def create_background_gif 
      push(0, 0, nil, type: BackgroundGifSprite)
    end
  end
end

module UI
  class Summary_Stat < SpriteStack
    # Show the IV ?
    SHOW_IV = false
    # Show the EV ?
    SHOW_EV = false

    def color_id
      $trainer.playing_girl ? 2 : 1
    end

    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :interface)
      @invisible_if_egg = []
      init_sprite
    end

    def no_egg(object)
      @invisible_if_egg << object
      return object
    end

    # Set the Pokemon shown by the UI
    # @param pokemon [PFM::Pokemon]
    def data=(pokemon)
      super
      fix_nature_texts(pokemon)
      fix_characteristic_text(pokemon)
      load_text_info(pokemon)
    end

    def fix_characteristic_text(creature)
      @characteristic_text.text = creature.characteristic
    end

    # Fix the nature text with colors and the right nature name
    # @param creature [PFM::Pokemon]
    def fix_nature_texts(creature)
      @nature_text.text = replace_nature_name_in_nature_texts(creature)
      # Load the stat color according to the nature
      nature = creature.nature.partition.with_index { |_, i| i != 3 }.flatten(1)
      1.upto(5) do |i|
        color = nature[i] < 100 ? 23 : 22
        color = 9 if nature[i] == 100
        @stat_name_texts[i - 1].load_color(color)
      end
    end


    # Load the text info
    # @param pokemon [PFM::Pokemon]
    def load_text_info(pokemon)
      return load_egg_text_info(pokemon) if pokemon.egg?

      time = Time.at(pokemon.captured_at)
      time_egg = pokemon.egg_at ? Time.at(pokemon.egg_at) : time

      # 1) get the data
      @capture_date     = time.strftime('%d/%m/%Y')
      @capture_location = pokemon.captured_zone_name.to_s
      @capture_level    = pokemon.captured_level

      # 2) Display in the 3 areas
      @txt_capture_date.text     = @capture_date
      @txt_capture_location.text = @capture_location
      @txt_capture_level.text    = "Rencontré au N. #{@capture_level}"
        
      hash = {
        '[VAR NUM2(0007)]' => time_egg.strftime('%d'),
        '[VAR NUM2(0006)]' => time_egg.strftime('%m'),
        '[VAR NUM2(0005)]' => time_egg.strftime('%Y'),
        '[VAR LOCATION(0008)]' => pokemon.egg_zone_name,
        '[VAR 0105(0008)]' => pokemon.egg_zone_name,
        '[VAR NUM3(0003)]' => pokemon.captured_level.to_s,
        '[VAR NUM2(0002)]' => time.strftime('%d'),
        '[VAR NUM2(0001)]' => time.strftime('%m'),
        '[VAR NUM2(0000)]' => time.strftime('%Y'),
        '[VAR LOCATION(0004)]' => pokemon.captured_zone_name,
        '[VAR 0105(0004)]' => pokemon.captured_zone_name
      }

      mem = pokemon.memo_text || []
      text = parse_text(mem[0] || 28, mem[1] || 25, hash).gsub(/([0-9.]) ([a-z]+ *)\:/i, "\\1 \n\\2:")
      text.gsub!('Level', "\nLevel") if $options.language == 'en'
      @text_info.multiline_text = '' #on rend invisible le texte de base
      # @id.load_color(pokemon.shiny ? 2 : 1)
    end

    # Load the text info when it's an egg
    # @param pokemon [PFM::Pokemon]
    def load_egg_text_info(pokemon)
      time_egg = pokemon.egg_at ? Time.at(pokemon.egg_at) : Time.new
      hash = {
        '[VAR NUM2(0007)]' => time_egg.strftime('%d'),
        '[VAR NUM2(0002)]' => time_egg.strftime('%d'),
        '[VAR NUM2(0006)]' => time_egg.strftime('%m'),
        '[VAR NUM2(0001)]' => time_egg.strftime('%m'),
        '[VAR NUM2(0005)]' => time_egg.strftime('%Y'),
        '[VAR NUM2(0000)]' => time_egg.strftime('%Y'),
        '[VAR LOCATION(0008)]' => pokemon.egg_zone_name,
        '[VAR 0105(0008)]' => pokemon.egg_zone_name,
        '[VAR NUM3(0003)]' => pokemon.captured_level.to_s,
        '[VAR LOCATION(0004)]' => pokemon.captured_zone_name,
        '[VAR 0105(0004)]' => pokemon.captured_zone_name
      }

      text = parse_text(28, egg_text_info(pokemon), hash).gsub(/([0-9.]) ([a-z]+ *):/i, "\\1 \n\\2:")
      text << "\n"
      text << parse_text(28, step_remaining_message(pokemon)).gsub(/([0-9.]) ([a-z]+ *):/i) { "#{$1} \n#{$2}:" }

      text.gsub!('Level', "\nLevel") if $options.language == 'en'
      @text_info.multiline_text = ''
    end

    def egg_text_info(pokemon)
      egg_how_obtained = pokemon.egg_how_obtained == :received ? 79 : 80
      mysterious_pokemon = pokemon.data.hatch_steps >= 10_240 ? 2 : 0

      return egg_how_obtained + mysterious_pokemon
    end

    def step_remaining_message(pokemon)
      if pokemon.step_remaining > 10_240
        return 87
      elsif pokemon.step_remaining > 2_560
        return 86
      elsif pokemon.step_remaining > 1_280
        return 85
      else
        return 84
      end
    end
           
    def init_ability
      ability_text = add_text(78, 153, 100, 16, "#{text_get(33, 142)}", color: 9, sizeid: 5)
      @ability_name = add_text(150, 153, 294, 16, :ability_name, type: SymText, color: 19, sizeid: 5)
      @ability_descr = add_text(58, 156 + 16, 294, 16, :ability_descr, type: SymMultilineText, color: 19, sizeid: 5)
    end

    # Update the graphics
    def update_graphics
      @backgroundgif2.update
    end

    def init_sprite
      @backgroundgif2 = create_background_gif
      init_stats
      @text_info = create_text_info
      init_ability
      @hp_container = create_hp_bg
      @hp = add_custom_sprite(create_hp_bar) # Copy/Paste from Party_Menu

      no_egg @txt_capture_date     = add_text(160, 69, 160, 16, '')
      no_egg @txt_capture_location = add_text(160, 89, 240, 16, '', color: color_id, sizeid: 5)
      no_egg @txt_capture_level    = add_text(160,109, 160, 16, '')

    end

    def create_text_info
      add_text(13, 138, 320, 16, '')
    end

    def create_background_gif 
      push(0, 0, nil, type: BackgroundGifSprite2)
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
      @stat.update_graphics
    end
  end
end


#-----------------------------------------------------------------------------
#                        TEXTS AND SPRITES
#-----------------------------------------------------------------------------




module UI
  class Summary_Stat < SpriteStack
    # Init the stat texts
    def init_stats
      @stat_name_texts = []
      texts = text_file_get(27)

      # --- Static part ---
      # @nature_text = add_line(0, '') # Nature
      # @characteristic_text = add_line(0, '') # Humeur
      @nature_text = add_text(160, 49, 80, 16, '', sizeid: 5, color: 19) 
      @characteristic_text = add_text(160, 129, 80, 16, '', sizeid: 5, color: 19) 

      # --- Noms des stats ---
      @hp_text = add_text(48, 15, 92, 16, texts[15], 0, 0, sizeid: 5, color: 9)  # HP
      @stat_name_texts << atk_text = add_text(23, 49, 92, 16, texts[18], 0, 0, sizeid: 5, color: 9)  # Attack
      @stat_name_texts << def_text = add_text(23, 69, 92, 16, texts[20], 0, 0, sizeid: 5, color: 9)  # Defense
      @stat_name_texts << atkspe_text = add_text(23, 89, 92, 16, texts[22], 0, 0, sizeid: 5, color: 9)  # Attack Spe
      @stat_name_texts << defspe_text = add_text(23, 109, 92, 16, texts[24], 0, 0, sizeid: 5, color: 9)  # Defense Spe
      @stat_name_texts << spe_text = add_text(23, 129, 92, 16, texts[26], 0, 0, sizeid: 5, color: 9) # Speed

      # --- Données des stats ---
      no_egg add_text(108, 15, 92, 16, :hp_text,   type: SymText, sizeid: 5, color: 19)  # HP value
      no_egg add_text(45, 48, 92, 16, :atk_basis, 2, type: SymText, sizeid: 5, color: 19)  # Attack value
      no_egg add_text(45, 68, 92, 16, :dfe_basis, 2, type: SymText, sizeid: 5, color: 19)  # Defense value
      no_egg add_text(45, 88, 92, 16, :ats_basis, 2, type: SymText, sizeid: 5, color: 19)  # Sp.Atk value
      no_egg add_text(45, 108, 92, 16, :dfs_basis, 2, type: SymText, sizeid: 5, color: 19) # Sp.Def value
      no_egg add_text(45, 128, 92, 16, :spd_basis, 2, type: SymText, sizeid: 5, color: 19) # Speed value
      init_ev_iv
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

    # Create the level text position
    def fix_level_text_position
      @level_text.x = 205
    end

    # Initialize the Memo part (static and dynamic texts)
    def init_memo
      texts = text_file_get(27)
      # --- Static part ---
      text0 = no_egg add_text(23, 14, 5, 16, texts[0], 0, 0, sizeid: 5, color: 9) # NoPokedex
      text2 = add_text(23, 34, 92, 16, texts[2], 0, 0, sizeid: 5, color: 9) # Nom
      text3 = no_egg add_text(23, 54, 92, 16, texts[3], 0, 0, sizeid: 5, color: 9) # Type
      text8 = no_egg add_text(23, 74, 92, 16, texts[8], 0, 0, sizeid: 5, color: 9) # DO
      text9 = no_egg add_text(23, 94, 92, 16, texts[9], 0, 0, sizeid: 5, color: 9) # Numero id
      text10 = no_egg add_text(23, 114, 9, 16, texts[10], 0, 0, sizeid: 5, color: 9) # Pt exp
      text12 = no_egg add_text(23, 154, 92, 16, texts[12], 0, 0, sizeid: 5, color: 9) # Next lvl
      text13 = no_egg add_text(205, 172, 92, 16, text_get(23, 7), color: 19, sizeid: 5) # Objet
      @level_text = no_egg(add_text(0, 21, 92, 16, texts[29], 0, 0, color: 19, sizeid: 5)) # Level
      
      # --- Data part ---
      add_text(102, 33, 92, 16, :name, type: SymText, sizeid: 5, color: 19) # name
      @id = no_egg add_text(102, 14, 92, 16, :id_text, type: SymText, sizeid: 5, color: 19) #No pokedex
      add_text(102, 134, 92, 16, :exp_text, type: SymText, sizeid: 5, color: 19) # exp
      add_text(102, 174, 92, 16, :exp_remaining_text, type: SymText, sizeid: 5, color: 19) # exp remaining
      @level_value = no_egg(add_text(220, 21, 92, 16, :level_text, type: SymText, sizeid: 5, color: 19)) # level
      no_egg add_text(102, 94, 92, 16, :trainer_id_text, type: SymText, sizeid: 5, color: 19) # trainer_id
      no_egg add_text(200, 193, 92, 16, :item_name, type: SymText, sizeid: 5, color: 19) #item name
    
      text13 = no_egg add_text(102, 74, 92, 16, :trainer_name, type: SymText, sizeid: 5, color: color_id) # trainer name
      text13.bold = true
      
      @type1sprite = no_egg push(102, 55, nil, type: Type1Sprite)
      @type2sprite = no_egg push(140, 55 + 0, nil, type: Type2Sprite)
    end
  end
end


# Commenting the text info in the first page of the memo
module UI
  class Summary_Memo < SpriteStack
    # Load the text info
    # @param pokemon [PFM::Pokemon]
    def load_text_info(pokemon)
      @id.load_color(pokemon.shiny ? color_id : 19)
    end
  end
end

#-----------------------------------------------------------------------------
#                      BACKGROUND POKEMON SPRITE
#-----------------------------------------------------------------------------


module UI
  # UI part displaying the generic information of the Pokemon in the Summary
  class Summary_Top < SpriteStack
    attr_reader :pokemon_sprite 
    attr_reader :pokemon_back_sprite

    def initialize(viewport)
      super(viewport, 0, 0, default_cache: :interface)
      init_sprite
    end

    # Set the Pokemon shown
    # @param pokemon [PFM::Pokemon]
    def data=(pokemon)
      super
      #@gender.ox = 88 - @name.real_width
      @gender.visible = false if NO_GENDER.include?(pokemon.db_symbol) || pokemon.egg?
      @item.visible = false if pokemon.egg?
      @ball.set_bitmap(data_item(pokemon.captured_with).icon, :icon)
      @star.visible = pokemon.shiny && !pokemon.egg?
      @pokerus.visible = pokemon.pokerus_affected? && !pokemon.egg?
      return unless @pokerus.visible

      @pokerus.load(pokemon.pokerus_cured? ? pokerus_cured_icon : pokerus_affected_icon, :interface)
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

    # @return [PokemonFaceSprite]
    def create_sprite
      @pokemon_sprite = push(237, 151, nil, type: PokemonFaceSprite)
      @pokemon_sprite.zoom_x = 1.28
      @pokemon_sprite.zoom_y = 1.28
      return @pokemon_sprite
    end

    def create_back_sprite
      @pokemon_back_sprite = push(237, 151, nil, type: PokemonBackSprite)
      @pokemon_back_sprite.zoom_x = 1.28
      @pokemon_back_sprite.zoom_y = 1.28
      @pokemon_back_sprite.visible = false
      return @pokemon_back_sprite
    end

    def create_back_sprite_lazily
      return if @pokemon_back_sprite

      @pokemon_back_sprite = push(237, 151, nil, type: PokemonBackSprite)
      @pokemon_back_sprite.zoom_x = 1.28
      @pokemon_back_sprite.zoom_y = 1.28
      @pokemon_back_sprite.data = @data if @data
      @pokemon_back_sprite.visible = true
    end

    def visible
      @stack[1].visible
    end
  end
end




module GamePlay
  # Scene displaying the Summary of a Pokemon
  class Summary < BaseCleanUpdate::FrameBalanced
  SUMMARY_ARROW_COOLDOWN = 200 # ms

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
        @stat = UI::Summary_Stat.new(@viewport),
        @skills = UI::Summary_Skills.new(@viewport)
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

    # When the player wants to see another Pokemon
    def update_switch_pokemon
      @pokemon = @party[@party_index]
      @index = 0 if @pokemon.egg?
      $game_system.se_play($data_system.decision_se)
      update_pokemon
      update_sprite_visibility # Assure la bonne visibilité des sprites
    end
  end
end


#-----------------------------------------------------------------------------
#                              BUTTONS BAR
#-----------------------------------------------------------------------------

module GamePlay
  class Summary
    KEYS = [
      %i[DOWN LEFT RIGHT B nil nil nil nil nil nil],
      %i[DOWN LEFT RIGHT B nil nil nil nil nil nil],
      %i[A LEFT RIGHT B nil nil nil nil nil nil],
      %i[A LEFT RIGHT B nil nil nil nil nil nil],
      %i[A LEFT RIGHT B nil nil nil nil nil nil],
      %i[A LEFT RIGHT B nil nil nil nil nil nil]
    ]
    # Create the generic base
    def create_base
      @base_ui = UI::GenericBaseMultiMode.new(@viewport, button_texts, KEYS, ctrl_id_state)
      init_win_text
    end

    def button_texts
      [
        ["","","","","","","",""], # état 0
        ["","","","","","","",""], # état 1
        ["","","","","","","",""], # état 2
        ["","","","","","","",""], # état 3
        ["","","","","","","",""], # état 4
        ["","","","","","","",""]  # état 5
      ]
    end


    def update_inputs_basic(allow_up_down = true)
      # On autorise la navigation haut/bas uniquement si on a plus d'un Pokémon
      allow_up_down &&= @party.size > 1

      # Changement d’UI (pas possible si c’est un œuf ou si on déplace une capacité)
      # Déplacement limité pour les boutons resume (pas possible de boucler de droite a gauche)
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

      @last_arrow_time ||= 0
      if allow_up_down
        now = Graphics.frame_count * (1000.0 / Graphics.frame_rate)
        if (Input.trigger?(:UP) || Input.press?(:UP)) && now - @last_arrow_time > SUMMARY_ARROW_COOLDOWN
          @party_index -= 1
          @party_index = @party.size - 1 if @party_index < 0
          update_switch_pokemon
          @last_arrow_time = now
          return true
        elsif (Input.trigger?(:DOWN) || Input.press?(:DOWN)) && now - @last_arrow_time > SUMMARY_ARROW_COOLDOWN
          @party_index += 1
          @party_index = 0 if @party_index >= @party.size
          update_switch_pokemon
          @last_arrow_time = now
          return true
        end
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

    # Update the move index from inputs
    def update_inputs_move_index
      if Input.trigger?(:UP)
        @uis[2].index -= 2
      elsif Input.trigger?(:DOWN)
        @uis[2].index += 2
      elsif Input.repeat?(:LEFT)
        @uis[2].index -= 1
      elsif Input.repeat?(:RIGHT)
        @uis[2].index += 1
      end
    end
  end
end



module GamePlay
  class Summary
    # Actions to do on the button according to the actual ID state of the buttons
    ACTIONS = [
      %i[mouse_memo mouse_stat mouse_skill mouse_quit mouse_next2 mouse_next mouse_exit_gameplay mouse_quit],
      %i[mouse_memo mouse_stat mouse_skill mouse_quit mouse_next2 mouse_next mouse_exit_gameplay mouse_quit],
      %i[mouse_memo mouse_stat mouse_skill mouse_quit mouse_next2 mouse_next mouse_exit_gameplay mouse_quit],
      %i[mouse_a object_id object_id mouse_cancel],
      %i[mouse_a object_id object_id mouse_cancel],
      %i[object_id object_id object_id mouse_quit]
    ]

    # Action performed when the player press on the [v] button with the mouse
    def mouse_next2
      $game_system.se_play($data_system.decision_se)
      @party_index -= 1
      @party_index = @party.size - 1 if @party_index < 0
      update_switch_pokemon
    end

    def mouse_memo
      $game_system.se_play($data_system.decision_se)
      @index = 0
      update_ui_visibility
    end

    def mouse_stat
      $game_system.se_play($data_system.decision_se)
      @index = 1
      update_ui_visibility
    end

    def mouse_skill
      $game_system.se_play($data_system.decision_se)
      @index = 2
      update_ui_visibility
    end

    def mouse_exit_gameplay
      $game_system.se_play($data_system.cancel_se)

      # Ferme le Summary
      @running = false

      # Ferme aussi le menu appelant (Party Menu)
      if $scene.is_a?(GamePlay::Party_Menu)
        $scene.instance_variable_set(:@running, false)
      end
    end
    # Update the UI visibility according to the index
    def update_ui_visibility
      @uis.each_with_index { |ui, index| ui.visible = index == @index }
      update_ctrl_state
    
      if @base_ui && @base_ui.instance_variable_defined?(:@ctrl)
        ctrl = @base_ui.instance_variable_get(:@ctrl)
        # Masquer chaque bouton resumeX si on est dans la page correspondante
        ctrl[0].visible = (@index != 0) # bouton_resume1 caché sur Memo
        ctrl[1].visible = (@index != 1) # bouton_resume2 caché sur Stats
        ctrl[2].visible = (@index != 2) # bouton_resume3 caché sur Skills
      end

      @top.visible = (@index != 1)
      if @top.instance_variable_defined?(:@star) && @pokemon
        star = @top.instance_variable_get(:@star)
        star.visible = @pokemon.shiny && !@pokemon.egg?
      end
    end
  end
end




