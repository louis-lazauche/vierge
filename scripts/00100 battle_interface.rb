#this file is responsible for changes in the battle UI

#this method is used to change the position of the info bars in the battle UI
module BattleUI
  class InfoBar < UI::SpriteStack

    HP_BAR_INFO = [48, 3, 0, 0, 6] # bw, bh, bx, by, nb_states
    EXP_BAR_INFO = [80, 2, 0, 0, 1]

    def base_position_v1
      return 5, 33 if enemy?

      return 142, 95
    end

    def create_hp
      @hp_background = add_sprite(*hp_background_coordinates, 'battle/battlebar_')
      # @type [UI::Bar]
      @hp_bar = push_sprite Bar.new(@viewport, *hp_bar_coordinates, RPG::Cache.interface('battle/bars_hp'), *HP_BAR_INFO)
      @hp_bar.data_source = :hp_rate
      with_font(22) do
        @hp_text = add_text(50, 14, 0, 10, enemy? ? :void_string : :hp_pokemon_number, type: SymText, color: 37)
        @hp_text.bold&= true
      end
    end

    def create_exp
      return if enemy?

      add_sprite(26, 22, 'battle/battlebar_exp')
      # @type [UI::Bar]
      @exp_bar = push_sprite Bar.new(@viewport, 27, 23, RPG::Cache.interface('battle/bars_exp'), *EXP_BAR_INFO)
      @exp_bar.data_source = :exp_rate
    end

    def hp_background_coordinates
      return enemy? ? [21, 7] : [33, 7]
    end

    def hp_bar_coordinates
      return enemy? ? [x + 38, y + 9] : [x + 50, y + 9]
    end

    def name_x_coordinates
      return 14 if enemy?
      return 10
    end

    def create_name
      with_font(21) do
        @name = add_text(name_x_coordinates, -4, 0, 16, :given_name, 0, 1, color: 37, type: SymText)
        @name.bold&= true
      end
    end

    def create_catch_sprite
      add_sprite(-2, -1, 'battle/ball', type: PokemonCaughtSprite)
    end

    def gender_x_coordinates
      return 70 if enemy?
      return 66
    end

    def create_gender_sprite
      add_sprite(gender_x_coordinates, -3, NO_INITIAL_IMAGE, type: GenderSprite)
    end

    def level_x_coordinates
      return 87 if enemy?
      return 83
    end

    def create_level
      with_font(24) do
        @levels = add_text(level_x_coordinates, -3, 0, 16, :level_pokemon_number, 0, 1, color: 37, type: SymText)
        @levels.bold&= true
      end
    end

    def status_x_coordinates
      return 1 if enemy?
      return 13
    end

    def create_status
      add_sprite(status_x_coordinates, 7, NO_INITIAL_IMAGE, type: StatusSprite)
    end

    # no star icon in infobars in 5th gen
    def create_star
      return push(119, -4, 'no_existing_file') if enemy?

      return push(6, 10, 'no_existing_file')
    end
  end
end

module PFM
  class Pokemon
    def hp_pokemon_number
      "#@hp / #{self.max_hp}".to_pokemon_number
    end
  end
end

#this module is responsible for changing the state of the info bars in the battle UI, in this case, we want to 
#show the infobar even when the player is choosing a move, so we need to change the state of the infobar
module Battle
  class Visual
    def set_info_state(state, pokemon = nil)
      if state == :choice
        show_info_bars
        hide_team_info
      elsif state == :move
        show_info_bars
        pokemon&.each { |target| show_info_bar(target) }
      elsif state == :move_animation
        hide_info_bars
        hide_team_info
      end
    end
  end
end


#change attacks coordinates
module BattleUI
  class SkillChoice < GenericChoice
    include SkillChoiceAbstraction
    # Coordinate of each buttons
    BUTTON_COORDINATE = [[0, 140], [93, 140], [0, 166], [93, 166]]
  end

  class PlayerChoice < GenericChoice
    include UI
    include PlayerChoiceAbstraction
    # Coordinate of each buttons
    BUTTON_COORDINATE = [[133, 130], [105, 140], [203, 140], [151, 165]]
  end
end

module BattleUI
  class SkillChoice
    # Monkey patch de la méthode update_key_index pour une navigation 2x2 sans boucle
    def update_key_index
      case @index
      when 0
        @index = 1 if Input.trigger?(:RIGHT) && button_visible?(1)
        @index = 2 if Input.trigger?(:DOWN)  && button_visible?(2)
      when 1
        @index = 0 if Input.trigger?(:LEFT)  && button_visible?(0)
        @index = 3 if Input.trigger?(:DOWN)  && button_visible?(3)
      when 2
        @index = 0 if Input.trigger?(:UP)    && button_visible?(0)
        @index = 3 if Input.trigger?(:RIGHT) && button_visible?(3)
      when 3
        @index = 1 if Input.trigger?(:UP)    && button_visible?(1)
        @index = 2 if Input.trigger?(:LEFT)  && button_visible?(2)
      end
    end

    private

    # Vérifie si un bouton donné est visible (attaque existante)
    def button_visible?(i)
      return false unless (button = @buttons[i])
      return button.visible
    end
    
    def create_buttons
      # @type [Array<MoveButton>]
      @buttons = 4.times.map do |i|
        add_sprite(*BUTTON_COORDINATE[i], NO_INITIAL_IMAGE, i, type: MoveButton)
      end
      @back_button = add_sprite(231, 168, 'battle/back_button')
    end
  end
end


module BattleUI
  class SkillChoice::SubChoice < UI::SpriteStack
    # Redéfinition du comportement lorsqu'on appuie sur B (ou X) pour quitter la description
    def action_b
      @move_description.hide
      @choice.show
      # NE PAS cacher les info bars ici, contrairement à la version d'origine
      $game_system.se_play($data_system.cancel_se)
    end
  end
end

module BattleUI
  class SkillChoice < GenericChoice
    class SubChoice < UI::SpriteStack
      def create_special_buttons
        @descr_button = add_sprite(12, 50, NO_INITIAL_IMAGE, @scene, :descr, type: SpecialButton)
        # ne pas créer le bouton de mega
      end

      def create_sprites
        create_special_buttons
        create_move_description
        # MoveDescription is independent UI so we create it standalone...
        @move_description = MoveDescription.new(@viewport)
        @move_description.visible = false
        # ...but we add the close button inside the MoveDescription stack so its
        # visibility and z-order follow the description window automatically.
        @descr_close_button = @move_description.add_sprite(-12, 67, 'battle/skill_info_back')
        @descr_close_button.visible = false
      end

      def reset
        @move_description.visible = false if @move_description
        @descr_button.refresh if @descr_button
        # no need to touch @descr_close_button: it's child of @move_description and will hide with it
      end

      def update_done
        action_x if Input.trigger?(:X) || (Mouse.trigger?(:LEFT) && @descr_button&.simple_mouse_in?)
      end

      def update_not_done
        return unless @move_description.done?

        action_b if Input.trigger?(:B) || Input.trigger?(:X) || (Mouse.trigger?(:LEFT) && @descr_close_button&.simple_mouse_in?)
      end

      def action_x
        unless (move = @choice.pokemon.moveset[@choice.index])
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        @move_description.data = move
        @move_description.show
        @choice.hide
        @scene.visual.show_info_bars(bank: 0)
        $game_system.se_play($data_system.decision_se)
      end

      # Action triggered when pressing B
      def action_b
        @move_description.hide
        @choice.show
        @scene.visual.hide_info_bars(bank: 0)
        $game_system.se_play($data_system.cancel_se)
      end
    end
  end
end

#define the position of the pokemon sprite in the battle UI
module BattleUI
  class PokemonSprite3D < PokemonSprite
    def base_position_v1
      return 58, -30 if enemy?

      return -34, 44
    end
  end
end


#define the zoom of the pokemon sprite in the battle UI
module BattleUI
  class PokemonSprite3D < PokemonSprite
    def sprite_zoom
      return enemy? ? 1.20 : 1.60
    end
  end
end


module Battle
  class Visual
    # Show the message "What will X do"
    # @param pokemon_index [Integer]
    def spc_show_message(pokemon_index)
      pokemon = @scene.logic.battler(0, pokemon_index)
      @scene.message_window.blocking = true
      @scene.message_window.wait_input = true
      text_to_show = parse_text(18, 71, '[VAR 010C(0000)]' => pokemon.given_name)
      @scene.display_message(text_to_show) if @scene.message_window.last_text != text_to_show
    end
  end
end


module Battle
  class Scene
    # Message Window of the Battle
    class Message < UI::Message::Window
      # Number of 60th of second to wait while message does not wait for user input
      MAX_WAIT = 60
    end
  end
end


module BattleUI
  # Sprite of a Pokemon in the battle
  class PokemonSprite < ShaderedSprite
    def play_entrance_darkening
      return unless self.shader # Vérifie que le shader est actif
      
      tone = [-100, -100, -100, 1.0] # RGB sombre, alpha = 1
      duration = 20 # En frames (20 frames ≈ 1/3 de seconde à 60 fps)

      color_updater = proc do |alpha|
        self.shader.set_float_uniform('color', tone[0..2] + [alpha])
      end

      ya = Yuki::Animation
      animation = ya::ScalarAnimation.new(duration, color_updater, :call, 1.0, 0.0)
      animation.resolver = self
      animation.start
    end
  end
end


module BattleUI
  # Sprite of a Pokemon in the battle
  class PokemonSprite < ShaderedSprite
    def load_battler(forced = false)
      return if under_substitute_effect? && !temporary_substitute_overwrite && !forced

      if forced || @last_pokemon&.id != @pokemon.id || @last_pokemon&.form != @pokemon.form || @last_pokemon&.code != @pokemon.code
        bitmap.dispose if @gif
        remove_instance_variable(:@gif) if instance_variable_defined?(:@gif)
        gif = pokemon.bank != 0 ? pokemon.gif_face : pokemon.gif_back
        if gif
          @gif = gif
          self.bitmap = Texture.new(gif.width, gif.height)
          gif.draw(bitmap)
        else
          self.bitmap = pokemon.bank != 0 ? pokemon.battler_face : pokemon.battler_back
        end
        load_shader(@pokemon)
        # ✅ Appel de l’effet d’assombrissement pour les Pokémon ennemis
        play_entrance_darkening if @pokemon.bank == 1 && self.shader
      end
      @last_pokemon = @pokemon.clone
      set_tone_status(@pokemon.status, true)
    end
  end
end

module BattleUI
  class SkillChoice < GenericChoice
    class MoveInfo < UI::SpriteStack
      # Create a new MoveInfo
      # @param viewport [Viewport]
      # @param move_choice [SkillChoice]
      def initialize(viewport, move_choice)
        super(viewport)
        @move_choice = move_choice
        create_sprites
      end

      # Set the move shown by the UI
      # @param pokemon [PFM::PokemonBattler]
      def data=(pokemon)
        super(move = pokemon.moveset[@move_choice.index])
        return unless move

        if move.pp == 0
          @pp_text.load_color(41)
        elsif move.pp <= move.ppmax / 3
          @pp_text.load_color(40)
        elsif move.pp <= move.ppmax / 2
          @pp_text.load_color(39)
        else
          @pp_text.load_color(38)
        end
        # Actualiser le sprite du type
        @type_sprite.sy = move.type
      end

      private

      def create_sprites
        @pp_background = add_sprite(100, 150, 'battle/pp_box', 1, 3, type: SpriteSheet)
        @pp_text = add_text(191, 155, 0, 16, :pp_text, 1, color: 10, type: UI::SymText)
        @type_sprite = add_sprite(191, 169, 'types_', 1, each_data_type.size, type: SpriteSheet)
      end
    end
  end
end

module Battle
  class Move
    def pp_text
      "PP  #{@pp}/#{@ppmax}"
    end
  end
end




module BattleUI
  class PlayerChoice < GenericChoice

    def create_buttons
      # @type [Array<Button>]
      @buttons = 4.times.map do |i|
        add_sprite(*BUTTON_COORDINATE[i], NO_INITIAL_IMAGE, i, type: ActionButton)
      end
    end

    class ActionButton < UI::SpriteStack
      # Create a new action button
      # @param viewport [Viewport]
      # @param index [Integer] Index of the action (0-3)
      def initialize(viewport, index)
        @index = index
        super(viewport)
        create_sprites
      end

      private

      def create_sprites
        add_background(background_filename)
      end

      def background_filename
        case @index
        when 0
          return 'battle/button_attack'
        when 1
          return 'battle/button_bag'
        when 2
          return 'battle/button_pokemon'
        when 3
          return 'battle/button_run'
        else
          return 'battle/button_attack' # fallback
        end
      end
    end
  end
end


module BattleUI
  # Object that display the Battle Party Balls of a trainer in Battle
  #
  # Remaining Pokemon, Pokemon with status
  class TrainerPartyBalls < UI::SpriteStack
    # Creates the go_in animation
    # @return [Yuki::Animation::TimedAnimation]

    def base_position_v1
      return @viewport.rect.width, 0 if enemy? && !@scene.battle_info.trainer_battle?
      return 0, 48 if enemy?

      return 120, 120
    end
    alias base_position_v2 base_position_v1
  end
end




module BattleUI
  class GenericChoice < UI::SpriteStack
    # Tell if the player is canceling his choice
    def canceling?
      return Input.trigger?(:B) || (Mouse.trigger?(:LEFT) && @back_button&.simple_mouse_in?)
    end
  end
end


module BattleUI
  class PlayerChoice < GenericChoice
    class SubChoice < UI::SpriteStack
      # hide the special buttons (out of the screen)
      def create_special_buttons
        @last_item_button = add_sprite(12, 300, NO_INITIAL_IMAGE, :last_item, type: SpecialButton)
        @info_button = add_sprite(2, 300, NO_INITIAL_IMAGE, :info, type: SpecialButton)
      end
    end
  end
end

module BattleUI
  class SkillChoice < GenericChoice
    class MoveDescription < UI::SpriteStack
      def create_sprites
        @background = add_background('battle/background')
        @box = add_sprite(0, 0, 'battle/description_box')
        @y = 61
        @skill_name = add_text(14, 13, 0, 16, :name, type: UI::SymText)
        @power_text = add_text(133, 13, 0, 16, text_get(27, 37), color: 10)
        @power_value = add_text(210, 13, 0, 16, :power_text, 2, type: UI::SymText)
        @accuracy_text = add_text(229, 13, 0, 16, text_get(27, 39), color: 10)
        @accuracy_value = add_text(306, 13, 0, 16, :accuracy_text, 2, type: UI::SymText)
        @description = add_text(14, 34, 284, 16, :description, color: 0, type: UI::SymMultilineText)
        @category_text = add_text(117, 88, 0, 16, text_get(27, 36), color: 10)
        @move_category = add_sprite(175, 89, NO_INITIAL_IMAGE, type: UI::CategorySprite)
      end
    end
  end
end

module BattleUI
  class SkillChoice < GenericChoice
    class SpecialButton < UI::SpriteStack
      def create_sprites
        @background = add_background(@type == :descr ? 'battle/skill_info' : 'battle/button_mega')
        @background.x = -12
        @background.y = 67
      end
      def refresh(mega = false)
        @background.set_bitmap(mega ? 'battle/button_mega_activated' : 'battle/button_mega', :interface) if @type == :mega
      end
    end
  end
end


module BattleUI
  class SkillChoice < GenericChoice
    
    # Set the button opacity
    def update_button_opacity
      buttons.each_with_index do |button, index|
        next unless button.visible

        button.opacity = index == @index ? 255 : 204
      end
    end

    class MoveButton < UI::SpriteStack
      def create_sprites
        @background = add_sprite(0, 0, 'battle/types', 1, each_data_type.size, type: SpriteSheet)
        @text = add_text(12, 3, 0, 16, :name, color: 38, type: UI::SymText)
      end
    end
  end
end


#handle the new added x_button(for tripple battles I think) dont know exactly what it is for but it causes problems if not handled
module BattleUI
  class PlayerChoice < GenericChoice
    class SubChoice < UI::SpriteStack
      # Update the button
      def update
        super
        @item_info.update
        done? ? update_done : update_not_done
      end

      # Reset the sub choice
      def reset
        @item_info.visible = false
        @bar_visibility = false
        @info_button.refresh
      end
    end
  end
end