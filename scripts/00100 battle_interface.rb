#this file is responsible for changes in the battle UI

#this method is used to change the position of the info bars in the battle UI
module BattleUI
  class InfoBar < UI::SpriteStack
    def base_position_v1
      return 2, 2 if enemy?

      return 185, 160
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
        show_team_info
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

# desactivate the x and y buttons
module BattleUI
  class PlayerChoice < GenericChoice
    class SubChoice < UI::SpriteStack

      # Monkey patch : on désactive les boutons spéciaux (X et Y)
      def create_special_buttons
        # NE RIEN FAIRE : on n’ajoute pas les sprites de X et Y
      end

      # Monkey patch : on n’appelle pas refresh sur les boutons supprimés
      def reset
        @item_info.visible = false
        @bar_visibility = false
      end

      # Monkey patch : on neutralise l'action de la touche Y
      def action_y
        # Rien
      end

      # Monkey patch : on neutralise l'action de la touche X
      def action_x
        # Rien
      end

      # Monkey patch : on supprime la détection des touches X et Y dans update_done
      def update_done
        # Aucun effet lié à Y ou X
      end

      # Monkey patch : idem dans update_not_done
      def update_not_done
        return unless @item_info.done?

        action_b if Input.trigger?(:B)
        action_a if Input.trigger?(:A)
      end

    end
  end
end


#change attacks coordinates
module BattleUI
  class SkillChoice < GenericChoice
    include SkillChoiceAbstraction
    # Coordinate of each buttons
    BUTTON_COORDINATE = [[10, 182], [150, 182], [10, 211], [150, 211]]
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
      update_button_opacity # Optionnel si tu veux que l'effet visuel suive
    end

    private

    # Vérifie si un bouton donné est visible (attaque existante)
    def button_visible?(i)
      return false unless (button = @buttons[i])
      return button.visible
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


#define the position of the pokemon sprite in the battle UI
module BattleUI
  class PokemonSprite3D < PokemonSprite
    def base_position_v1
      return 20, 18 if enemy?

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


# module Battle
#   class Visual
#     # Show the message "What will X do"
#     # @param pokemon_index [Integer]
#     def spc_show_message(pokemon_index)
#       pokemon = @scene.logic.battler(0, pokemon_index)
#       @scene.message_window.wait_input = true
#       text_to_show = parse_text(18, 71, '[VAR 010C(0000)]' => pokemon.given_name)
#       @scene.display_message(text_to_show) if @scene.message_window.last_text != text_to_show
#     end
#   end
# end




module Battle
  class Visual
    # Begining of the show_player_choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    def show_player_choice_begin(pokemon_index)
      @message_box = UI::MessageBattleBox.new(@viewport)
      @message_box.z=(0)
      Graphics.sort_z
      @message_box.visible = true
      pokemon = @scene.logic.battler(0, pokemon_index)
      @locking = true
      @player_choice_ui.reset(@scene.logic.switch_handler.can_switch?(pokemon))
      if @player_choice_ui.out?
        @player_choice_ui.go_in
        @animations << @player_choice_ui
        wait_for_animation
      end
      spc_start_bouncing_animation(pokemon_index)
    end

    # Loop process of the player choice
    def show_player_choice_loop
      loop do
        @scene.update
        @player_choice_ui.update
        Graphics.update
        break if @player_choice_ui.validated?
      end
    end

    # End of the show_player_choice
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    def show_player_choice_end(pokemon_index)
      @player_choice_ui.go_out
      @animations << @player_choice_ui
      if @player_choice_ui.result != :attack
        spc_stop_bouncing_animation(pokemon_index)
        wait_for_animation
      end
      @locking = false
    end
  end
end

module UI
  class MessageBattleBox < SpriteStack
    def initialize(viewport)
       super(viewport, 131, 35, default_cache: :pokedex)

       create_sprites
    end

    def update
      # pas forcément nécessaire mais peut-être utile à monkey patch
    end

    def data=(pokemon)
      super(pokemon)
    end

    def create_sprites
      add_sprite(8, 4, 'message_box')
      add_text(9, 67, 116, 16, :pokedex_weight)
    end
  end
end



module BattleUI
  # Object that show the Battle Bar of a Pokemon in Battle
  # @note Since .25 InfoBar completely ignore bank & position info about Pokemon to make thing easier regarding positionning
  class InfoBar < UI::SpriteStack
    # The information of the HP Bar
    HP_BAR_INFO = [64, 4, 0, 0, 6] # bw, bh, bx, by, nb_states
  end
end


module BattleUI
  # Object that show the Battle Bar of a Pokemon in Battle
  # @note Since .25 InfoBar completely ignore bank & position info about Pokemon to make thing easier regarding positionning
  class InfoBar < UI::SpriteStack
    def hp_background_coordinates
      return enemy? ? [8, 12] : [18, 12]
    end

    def hp_bar_coordinates
      return enemy? ? [x + 50, y + 23] : [x + 33, y + 13]
    end
  end
end


module Battle
  class Scene
    # Message Window of the Battle
    class Message < UI::Message::Window
      # Process the wait user input phase
      def wait_user_input
        create_skipper_wait_animation unless @skipper_wait_animation
        if @skipper_wait_animation.done?
          terminate_message
        else
          @skipper_wait_animation.update
        end
      end
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
