module Battle
  module Effects
    class Ability
      class GrassPelt < Ability
        # Give the dfe modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def dfe_modifier
          return 1.5 if @logic.field_terrain_effect.grassy?

          return super
        end
      end

      register(:grass_pelt, GrassPelt)
    end
  end
end
