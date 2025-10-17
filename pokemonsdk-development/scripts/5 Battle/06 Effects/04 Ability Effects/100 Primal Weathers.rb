module Battle
  module Effects
    class Ability
      class DesolateLand < Ability
        # Create a new PrimalWeather effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @ability_removal_process = false
        end

        # Liste des temps qui peuvent changer
        WEATHERS = %i[hardsun hardrain strong_winds]
        # Function called when a creature has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] creature that is switched out
        # @param with [PFM::PokemonBattler] creature that is switched in
        def on_switch_event(handler, who, with)
          if with == @target
            weather_handler = handler.logic.weather_change_handler
            return unless weather_handler.weather_appliable?(weather_symbol)

            handler.scene.visual.show_ability(with)
            weather_handler.weather_change(weather_symbol, nil)
            handler.scene.visual.show_rmxp_animation(with, anim)
          elsif who == @target
            return unless $env.current_weather_db_symbol == weather_symbol
            return if handler.logic.all_alive_battlers.any? { |battler| primal_weather_ability?(battler) && battler != @target }

            handler.logic.weather_change_handler.weather_change(:none, 0)
            handler.scene.display_message_and_wait(parse_text(18, msg))
          end
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if target != @target
          return unless $env.current_weather_db_symbol == weather_symbol
          return if handler.logic.all_alive_battlers.any? { |battler| primal_weather_ability?(battler) && battler != @target }

          handler.logic.weather_change_handler.weather_change(:none, 0)
          handler.scene.display_message_and_wait(parse_text(18, msg))
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def on_post_weather_change(handler, weather_type, last_weather)
          return unless weather_type == :none
          return if @ability_removal_process

          handler.scene.visual.show_ability(@target)
          handler.logic.weather_change_handler.weather_change(weather_symbol, nil)
          handler.scene.visual.show_rmxp_animation(@target, anim)
        end

        # Function called when a pre_ability_change is checked
        # @param handler [Battle::Logic::AbilityChangeHandler]
        # @param _db_symbol [Symbol] Symbol ID of the ability to give
        # @param target [PFM::PokemonBattler]
        # @param _launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param _skill [Battle::Move, nil] Potential move used
        def on_pre_ability_change(handler, _db_symbol, target, _launcher, _skill)
          return unless target == @target
          return unless $env.current_weather_db_symbol == weather_symbol
          return unless handler.logic.all_alive_battlers.none? { |battler| primal_weather_ability?(battler) && battler != @target }

          @ability_removal_process = true
          handler.logic.weather_change_handler.weather_change(:none, 0)
          @ability_removal_process = false
          handler.scene.display_message_and_wait(parse_text(18, msg))
        end

        private

        # Weather concerned
        # @return [Symbol] weather symbol
        def weather_symbol
          return :hardsun
        end

        # Weather setting ability
        # @param creature [PFM::PokemonBattler]
        # @return [Boolean] true if the creature has the ability that sets the weather
        def primal_weather_ability?(creature)
          return creature.has_ability?(:desolate_land)
        end

        # Weather setup animation id
        # @return [Integer] id
        def anim
          return 492
        end

        # Weather clear text line
        # @return [Integer] id
        def msg
          return 272
        end
      end
      register(:desolate_land, DesolateLand)

      class PrimordialSea < DesolateLand
        private

        # Weather concerned
        # @return [db_symbol] weather
        def weather_symbol
          return :hardrain
        end

        # Weather setting ability
        # @param creature [PFM::PokemonBattler]
        # @return [Boolean] true if the creature has the ability that sets the weather
        def primal_weather_ability?(creature)
          return creature.has_ability?(:primordial_sea)
        end

        # Weather setup animation id
        # @return [Integer] id
        def anim
          return 493
        end

        # Weather clear text line
        # @return [Integer] id
        def msg
          return 270
        end
      end
      register(:primordial_sea, PrimordialSea)

      class DeltaStream < DesolateLand
        private

        # Weather concerned
        # @return [db_symbol] weather
        def weather_symbol
          return :strong_winds
        end

        # Weather setting ability
        # @param creature [PFM::PokemonBattler]
        # @return [Boolean] true if the creature has the ability that sets the weather
        def primal_weather_ability?(creature)
          return creature.has_ability?(:delta_stream)
        end

        # Weather setup animation id
        # @return [Integer] id
        def anim
          return 566
        end

        # Weather clear text line
        # @return [Integer] id
        def msg
          return 274
        end
      end
      register(:delta_stream, DeltaStream)
    end
  end
end
