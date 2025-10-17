module Battle
  module Effects
    class AbilitySuppressed < PokemonTiedEffectBase
      # The origin of the effect (e.g. :gastro_acid)
      # @return [Symbol]
      attr_reader :origin

      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param origin [Symbol] the origin of the effect (e.g. :gastro_acid)
      def initialize(logic, pokemon, origin)
        super(logic, pokemon)
        @origin = origin
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :ability_suppressed
      end

      private

      # Transfer the effect to the given pokemon via baton switch
      # @param with [PFM::Battler] the pokemon switched in
      # @return [Battle::Effects::PokemonTiedEffectBase, nil] the effect to give to the switched in pokemon, nil if there is this effect isn't transferable via baton pass
      def baton_switch_transfer(with)
        return self.class.new(@logic, with, @origin)
      end
    end
  end
end
