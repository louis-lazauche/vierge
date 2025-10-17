module Battle
  class Move
    # class managing FairyLock move
    class FairyLock < Move
      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if logic.terrain_effects.has?(:fairy_lock)
          show_usage_failure(user)
          return false
        end

        return true
      end

      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        logic.terrain_effects.add(Effects::FairyLock.new(@logic))
        logic.scene.display_message_and_wait(parse_text(18, 258))
      end
    end
    Move.register(:s_fairy_lock, FairyLock)
  end
end
