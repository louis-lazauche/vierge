module Battle
  module Effects
    class Ability
      class NeutralizingGas < Ability
        # Create a new Neutralizing Gas effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
          @activated_turn = -1
        end

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return retrieve_abilities(who) if who != with && who == @target

          suppress_abilities(with) if with == @target
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if target != @target
          return unless @activated

          find_replacement(target)
        end

        # Function called when a pre_ability_change is checked
        # @param handler [Battle::Logic::AbilityChangeHandler]
        # @param db_symbol [Symbol] Symbol ID of the ability to give
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_pre_ability_change(handler, db_symbol, target, launcher, skill)
          return if target != @target
          return if db_symbol == target.battle_ability_db_symbol
          return unless @activated

          find_replacement(target)
        end

        # If Neutralizing Gas effect is currently activated by this pokemon
        # @return [Boolean]
        def activated?
          return @activated
        end
        alias activated activated?

        # Return the turn when the ability was activated
        # @return [Integer]
        def activated_turn
          return @activated_turn
        end

        # Tell if the ability has been activated this turn
        # @return [Boolean]
        def activated_this_turn?
          return activated? && activated_turn == $game_temp.battle_turn
        end

        private

        # Suppress the ability of each battlers if the conditions are fullfilled
        # @param ability_owner [PFM::PokemonBattler] Battler that is using the ability
        def suppress_abilities(ability_owner)
          return unless ability_owner == @target

          unless @activated
            @logic.scene.visual.show_ability(ability_owner, true)
            @logic.scene.display_message_and_wait(parse_text(60, 407))
            @logic.scene.visual.hide_ability(ability_owner)
          end

          @logic.all_alive_battlers.each do |battler|
            next if battler.effects.has?(:ability_suppressed)
            next if battler.has_ability?(db_symbol)
            next unless @logic.ability_change_handler.can_change_ability?(battler)

            @logic.ability_change_handler.disable_ability(battler, db_symbol)
          end

          @activated = true
          @activated_turn = $game_temp.battle_turn
        end

        # Retrieve the ability of each battlers if the conditions are fullfilled
        # @param ability_owner [PFM::PokemonBattler] Battler that is using the ability
        def retrieve_abilities(ability_owner)
          return unless @activated

          @logic.scene.display_message_and_wait(parse_text(60, 408))

          @logic.all_alive_battlers.each do |battler|
            # @type [Battle::Effects::AbilitySuppressed]
            effect = battler.effects.get(:ability_suppressed)
            next if effect.nil? || effect.origin != db_symbol

            battler.effects.get(:ability_suppressed).kill
            battler.effects.delete_specific_dead_effect(:ability_suppressed)
            battler.ability_effect.on_switch_event(@logic.switch_handler, battler, battler)
          end

          @activated = false
          @activated_turn = -1
        end

        # Looking for a replacement to take over the effect
        # @param ability_owner [PFM::PokemonBattler] Battler that is using the ability
        def find_replacement(ability_owner)
          battlers = @logic.all_alive_battlers.select { |battler| battler.has_ability?(db_symbol) }
          battlers.reject! { |battler| battler == ability_owner }
          return retrieve_abilities(ability_owner) if battlers.empty?

          # @type [PFM::PokemonBattler]
          battler = battlers.max_by(&:spd)
          battler.ability_effect.on_switch_event(@logic.switch_handler, battler, battler)
        end
      end

      register(:neutralizing_gas, NeutralizingGas)
    end
  end
end
