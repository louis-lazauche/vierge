module Battle
  module Effects
    class Ability
      class FlowerGift < Ability
        # Create a new FlowerGift effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @affect_allies = true
        end

        # Function called when a creature has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Creature that is switched out
        # @param with [PFM::PokemonBattler] Creature that is switched in
        def on_switch_event(handler, who, with)
          return unless with == @target

          handle_weather_form(handler, with)
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def on_post_weather_change(handler, weather_type, last_weather)
          handle_weather_form(handler, @target)
        end

        # Function called when a pre_ability_change is checked
        # @param handler [Battle::Logic::AbilityChangeHandler]
        # @param _db_symbol [Symbol] Symbol ID of the ability to give
        # @param target [PFM::PokemonBattler]
        # @param _launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param _skill [Battle::Move, nil] Potential move used
        def on_pre_ability_change(handler, _db_symbol, target, _launcher, _skill)
          return unless target == @target

          handle_form(handler, target, overcast, show_ability: false)
        end

        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 1 unless $env.global_sunny?

          return 1.5
        end

        # Give the dfs modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfs_modifier
          action = @logic.current_action
          return 1 unless $env.global_sunny?
          return 1 if action.is_a?(Actions::Attack) && !action.launcher.can_be_lowered_or_canceled?

          return 1.5
        end

        private

        # Change the target to its appropriate form according to the weather
        # @param handler [Battle::Logic::ChangeHandlerBase]
        # @param target [PFM::PokemonBattler]
        def handle_weather_form(handler, target)
          reason = overcast
          reason = sunshine if $env.global_sunny?
          handle_form(handler, target, reason)
        end

        # Handle the target's form change
        # @param handler [Battle::Logic::ChangeHandlerBase]
        # @param target [PFM::PokemonBattler]
        # @param reason [Symbol] which form
        # @param show_ability [Boolean] whether to display the target's ability
        def handle_form(handler, target, reason, show_ability: true)
          return if target.form == target.cherrim_form(reason)

          target.form_calibrate(reason)

          if show_ability
            handler.scene.visual.show_ability(target)
            handler.scene.visual.wait_for_animation
          end

          handler.scene.visual.show_switch_form_animation(target)
        end

        # Symbol for Cherrim's Sunshine Form
        # @return [Symbol]
        def sunshine
          return :sunshine
        end

        # Symbol for Cherrim's Overcast Form
        # @return [Symbol]
        def overcast
          return :overcast
        end
      end

      register(:flower_gift, FlowerGift)
    end
  end
end
