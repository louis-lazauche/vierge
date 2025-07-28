module Battle
  class Move
    # @note This move becomes physical if the user's Atk is higher than its SpA; otherwise, it stays special.
    #       It considers the user's stat stage modifiers but not other effects like held items and abilities.
    # @see https://bulbapedia.bulbagarden.net/wiki/Photon_Geyser_(move)#Effect
    class PhotonGeyser < Basic
      # Method calculating the damages done by the actual move
      # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @note The formula is the following:
      #       (((((((Level * 2 / 5) + 2) * BasePower * [Sp]Atk / 50) / [Sp]Def) * Mod1) + 2) *
      #         CH * Mod2 * R / 100) * STAB * Type1 * Type2 * Mod3)
      # @return [Integer]
      def damages(user, target)
        raw_atk = (user.atk_basis * user.atk_modifier).floor
        raw_ats = (user.ats_basis * user.ats_modifier).floor
        @physical = raw_atk > raw_ats
        @special = !@physical
        log_data("Photon Geyser's category: #{@physical ? :physical : :special}")

        return super
      end

      # Is the skill physical?
      # @return [Boolean]
      def physical?
        return @physical.nil? ? super : @physical
      end

      # Is the skill special?
      # @return [Boolean]
      def special?
        return @special.nil? ? super : @special
      end
    end
    Move.register(:s_photon_geyser, PhotonGeyser)
  end
end
