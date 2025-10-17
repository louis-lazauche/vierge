module BattleUI
  # Object that show the Battle Bar of a Pokemon in Battle
  # @note Since .25 InfoBar completely ignore bank & position info about Pokemon to make thing easier regarding positionning
  class InfoBar < UI::SpriteStack
    include UI
    include GoingInOut
    include MultiplePosition

    # The information of the HP Bar
    HP_BAR_INFO = [92, 4, 0, 0, 6] # bw, bh, bx, by, nb_states
    HP_BAR_INFO_V3 = [63, 4, 0, 0, 6]
    # The information of the Exp Bar
    EXP_BAR_INFO = [88, 2, 0, 0, 1]
    EXP_BAR_INFO_V3 = [58, 2, 0, 0, 1]

    # Get the Pokemon shown by the InfoBar
    # @return [PFM::PokemonBattler]
    attr_reader :pokemon
    # Get the animation handler
    # @return [Yuki::Animation::Handler{ Symbol => Yuki::Animation::TimedAnimation}]
    attr_reader :animation_handler
    # Get the position of the pokemon shown by the sprite
    # @return [Integer]
    attr_reader :position
    # Get the bank of the pokemon shown by the sprite
    # @return [Integer]
    attr_reader :bank
    # Get the scene linked to this object
    # @return [Battle::Scene]
    attr_reader :scene

    # Create a new InfoBar
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    # @param pokemon [PFM::Pokemon]
    # @param bank [Integer]
    # @param position [Integer]
    def initialize(viewport, scene, pokemon, bank, position)
      super(viewport)
      @is_triple_battle = $game_temp.vs_type == 3
      @bank = bank
      @position = position
      @scene = scene
      create_sprites
      self.pokemon = pokemon
    end

    # Create the animation
    def create_animation
      @animation_handler = Yuki::Animation::Handler.new
    end

    # Update the InfoBar
    def update
      @animation_handler.update
    end

    # Tell if the InfoBar animations are done
    # @return [Boolean]
    def done?
      return @animation_handler.done?
    end

    # Sets the Pokemon shown by this bar
    # @param pokemon [PFM::Pokemon]
    def pokemon=(pokemon)
      @pokemon = pokemon
      refresh
    end

    # Refresh the bar contents
    def refresh
      if @pokemon
        self.visible = true
        self.data = @pokemon
        set_position(*sprite_position) if in?
      else
        self.visible = false
      end
    end

    # Set the Creature to show in the Info Bar
    def data=(pokemon)
      super
      @star.visible = pokemon.shiny && !pokemon.egg?
    end

    # Return a suffix for 3v3 battle resources
    # @return [String]
    def suffix_3v3
      return $game_temp.vs_type == 3 ? '_3v3' : ''
    end

    private

    # Get the base position of the Pokemon in 1v1
    # @return [Array(Integer, Integer)]
    def base_position_v1
      return 184, 9 if enemy?

      return 2, 198
    end

    # Get the base position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def base_position_v2
      return 48, 9 if enemy?

      return 2, 195
    end

    # Get the base position of the Pokemon in 3v3
    # @return [Array(Integer, Integer)]
    def base_position_v3
      return 2, 5 if enemy?

      return 2, 193
    end

    # Get the offset position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def offset_position_v2
      return 136, 3 if enemy?

      return 136, -3
    end

    # Get the offset position of the Pokemon in 3v3
    # @return [Array(Integer, Integer)]
    def offset_position_v3
      return 106, 3 if enemy?

      return 106, 3
    end

    def create_sprites
      create_background
      create_hp
      create_exp
      create_name
      create_catch_sprite
      create_gender_sprite
      create_level
      create_status
      @star = create_star
    end

    def create_background
      @background = add_sprite(0, 0, NO_INITIAL_IMAGE, type: Background)
    end

    def create_hp
      hp_bar_info = @is_triple_battle ? HP_BAR_INFO_V3 : HP_BAR_INFO
      hp_text_x = @is_triple_battle ? 36 : 66

      @hp_background = add_sprite(*hp_background_coordinates, "battle/battlebar#{suffix_3v3}_")
      # @type [UI::Bar]
      @hp_bar = push_sprite Bar.new(@viewport, *hp_bar_coordinates, RPG::Cache.interface("battle/bars_hp#{suffix_3v3}"), *hp_bar_info)
      @hp_bar.data_source = :hp_rate
      @hp_text = add_text(hp_text_x, 17, 0, 10, enemy? ? :void_string : :hp_pokemon_number, type: SymText, color: 10)
    end

    def create_exp
      return if enemy?

      add_sprite(36, 30, "battle/battlebar_exp#{suffix_3v3}")
      # @type [UI::Bar]
      @exp_bar = push_sprite Bar.new(@viewport, 37, 31, RPG::Cache.interface("battle/bars_exp#{suffix_3v3}"), *EXP_BAR_INFO_V3)
      @exp_bar.data_source = :exp_rate
    end

    def hp_background_coordinates
      return enemy? ? [8, 12] : [18, 12]
    end

    def hp_bar_coordinates
      return enemy? ? [x + 23, y + 13] : [x + 33, y + 13]
    end

    def create_name
      with_font(20) do
        @name = add_text(8, -4, 0, 16, :given_name, 0, 1, color: 10, type: SymText)
      end
    end

    def create_catch_sprite
      ball_sprite_x = @is_triple_battle ? 89 : 118
      add_sprite(ball_sprite_x, 10, 'battle/ball', type: PokemonCaughtSprite)
    end

    def create_gender_sprite
      gender_sprite_x = @is_triple_battle ? 71 : 81
      add_sprite(gender_sprite_x, -3, NO_INITIAL_IMAGE, type: GenderSprite)
    end

    def create_level
      level_text_x = @is_triple_battle ? 80 : 91
      add_text(level_text_x, -6, 0, 16, :level_pokemon_number, 0, 1, color: 10, type: SymText)
    end

    def create_status
      add_sprite(8, 19, NO_INITIAL_IMAGE, type: StatusSprite)
    end

    def create_star
      star_x = @is_triple_battle ? 90 : 119
      star_y = @is_triple_battle ? 24 : -4

      return push(star_x, star_y, 'shiny') if enemy?

      return push(6, 10, 'shiny')
    end

    # Creates the go_in animation
    # @return [Yuki::Animation::TimedAnimation]
    def go_in_animation
      origin_y = enemy? ? -@background.height : @viewport.rect.height + @background.height
      return Yuki::Animation.move_discreet(0.2, self, x, origin_y, *sprite_position)
    end

    # Creates the go_out animation
    # @return [Yuki::Animation::TimedAnimation]
    def go_out_animation
      target_y = enemy? ? -@background.height : @viewport.rect.height + @background.height
      return Yuki::Animation.move_discreet(0.2, self, *sprite_position, x, target_y)
    end

    # Class showing the ball sprite if the Pokemon is enemy and caught
    class PokemonCaughtSprite < ShaderedSprite
      # Set the Pokemon Data
      # @param pokemon [PFM::Pokemon]
      def data=(pokemon)
        self.visible = pokemon.bank != 0 && $pokedex.creature_caught?(pokemon.id, pokemon.form)
      end
    end

    # Class showing the right background depending on the pokemon
    class Background < ShaderedSprite
      # Set the Pokemon Data
      # @param pokemon [PFM::Pokemon]
      def data=(pokemon)
        return unless (self.visible = pokemon)

        set_bitmap(background_filename(pokemon), :interface)
      end

      # Name of the background based on the creature shown
      # @param pokemon [PFM::PokemonBattler]
      # @return [String]
      def background_filename(pokemon)
        return "battle/battlebar_enemy#{suffix_3v3}" if pokemon.bank != 0
        return "battle/battlebar_actor#{suffix_3v3}" if pokemon.from_party?

        return "battle/battlebar_ally#{suffix_3v3}"
      end

      # Return a suffix for 3v3 battle resources
      # @return [String]
      def suffix_3v3
        return $game_temp.vs_type == 3 ? '_3v3' : ''
      end
    end
  end
end
