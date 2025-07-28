module Battle
  module Effects
    class Ability
      class PurePower < Ability
        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 2
        end
      end

      register(:pure_power, PurePower)
      register(:huge_power, PurePower)
    end
  end
end
