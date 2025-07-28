module Battle
  module Effects
    class Ability
      class Forecast < Ability
        # @return [Array<Symbol>]
        WEATHERS = %i[rain hardrain sunny hardsun hail snow]
        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return unless with == @target
          return unless WEATHERS.include?($env.current_weather_db_symbol)

          handle_weather_form(handler, with)
        end

        # Function called after the weather was changed (on_post_weather_change)
        # @param handler [Battle::Logic::WeatherChangeHandler]
        # @param weather_type [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        # @param last_weather [Symbol] :none, :rain, :sunny, :sandstorm, :hail, :fog
        def on_post_weather_change(handler, weather_type, last_weather)
          return if last_weather == weather_type
          return unless WEATHERS.include?(weather_type)

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

          handle_form(handler, target, 0, :base, show_ability: false)
        end

        private

        # Handle the right change of form in relation to the weather
        # @param handler [Battle::Logic::SwitchHandler]
        # @param battler [PFM::PokemonBattler]
        def handle_weather_form(handler, battler)
          return handle_form(handler, battler, 2, :fire) if $env.global_sunny?
          return handle_form(handler, battler, 3, :rain) if $env.global_rain?
          return handle_form(handler, battler, 6, :ice) if $env.hail?

          return handle_form(handler, battler, 0, :base)
        end

        # Handle the change of form
        # @param handler [Battle::Logic::SwitchHandler]
        # @param battler [PFM::PokemonBattler]
        # @param form_number [Integer]
        # @param reason [Symbol]
        # @param show_ability [Boolean]
        def handle_form(handler, battler, form_number, reason, show_ability: true)
          return if battler.form == form_number

          if show_ability
            handler.scene.visual.show_ability(battler)
            handler.scene.visual.wait_for_animation
          end

          battler.form_calibrate(reason)
          handler.scene.visual.show_switch_form_animation(battler)
        end
      end

      register(:forecast, Forecast)
    end
  end
end
