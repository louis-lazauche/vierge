module Battle
  module Effects
    class Ability
      class Guts < Ability
        # Give the atk modifier over given to the Pokemon with this effect
        # @return [Float, Integer] multiplier
        def atk_modifier
          return 1 unless @target.status?

          return 1.5
        end
      end

      register(:guts, Guts)
    end
  end
end
