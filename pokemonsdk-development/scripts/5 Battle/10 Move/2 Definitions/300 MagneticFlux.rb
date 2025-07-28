module Battle
  class Move
    # Magnetic Flux move
    class MagneticFlux < Move
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        actual_targets.any? { |target| %i[plus minus].include?(target.ability_db_symbol) }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless %i[plus minus].include?(target.ability_db_symbol)

          scene.logic.stat_change_handler.stat_change_with_process(:dfe, 1, target, user, self)
          scene.logic.stat_change_handler.stat_change_with_process(:dfs, 1, target, user, self)
        end
      end
    end
    Move.register(:s_magnetic_flux, MagneticFlux)
  end
end
