module Battle
  class Move
    class CoreEnforcer < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return false if actual_targets.all? { |target| target.effects.has?(:ability_suppressed) }
        return false if actual_targets.none? { |target| action_played_this_turn?(target) }
        return false if actual_targets.all?(&:dead?)

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:ability_suppressed)
          next unless action_played_this_turn?(target)
          next if target.dead?

          @logic.ability_change_handler.disable_ability(target, db_symbol, user, self)
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 565, target))
        end
      end

      private

      # Check if the target has played an action this turn before this move
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def action_played_this_turn?(target)
        played_actions = @logic.turn_actions - @logic.actions

        result = played_actions.any? do |action|
          (action.is_a?(Actions::Attack) && action.launcher == target) ||
            (action.is_a?(Actions::Item) && action.user == target)
        end

        return result
      end
    end

    Move.register(:s_core_enforcer, CoreEnforcer)
  end
end
