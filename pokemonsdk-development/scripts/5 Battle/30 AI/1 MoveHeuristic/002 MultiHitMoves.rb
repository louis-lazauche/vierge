module Battle
  module AI
    class MoveHeuristicBase
      # Class describing the heuristic of a move that hits multiple times
      # @note This class is used for moves like Fury Swipes, Rock Blast, etc.
      #       these moves have very low power but can hit multiple times,
      #       effectively having always low heuristic despite potential strong power.
      #       Minimum AI level: 3 -> "can_see_move_kind" set to true.
      class MultiHit < MoveHeuristicBase
        POWER_MEAN = 200.0
        POWER_STD = 150 * Math.sqrt(2)

        # Create a new Multi Hit Move Heuristic
        def initialize
          super(false, true, false)
        end

        # Compute the heuristic
        # @param move [Battle::Move]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param ai [Battle::AI::Base]
        # @return [Float]
        def compute(move, user, target, ai)
          effectiveness = move.calc_stab(user, move.definitive_types(user, target)) * move.type_modifier(user, target)
          power_multiplier = move_hit_multiplier(user)
          power = move.real_base_power(user, target) * power_multiplier
          # Base damage calculation formula
          est_damage = 0.75 + 0.125 * (1 + Math.erf((power * effectiveness - POWER_MEAN) / POWER_STD))
          return super * est_damage
        end

        # Process the power amplification according to potential hit amount
        # @param user [PFM::PokemonBattler]
        # @return [Float]
        def move_hit_multiplier(user)
          hit_amount = 3.0
          hit_amount = 4.5 if user.hold_item?(:loaded_dice)
          hit_amount = 5.0 if user.has_ability?(:skill_link)
          return hit_amount
        end
      end

      class TwoHit < MultiHit
        # Process the power amplification according to potential hit amount
        # @param user [PFM::PokemonBattler]
        # @return [Float]
        def move_hit_multiplier(_)
          return 2.0
        end
      end

      class ThreeHit < MultiHit
        # Process the power amplification according to potential hit amount
        # @param user [PFM::PokemonBattler]
        # @return [Float]
        def move_hit_multiplier(_)
          return 3.0
        end
      end

      class TripleKick < MultiHit
        # Process the power amplification according to potential hit amount
        # @param user [PFM::PokemonBattler]
        # @return [Float]
        def move_hit_multiplier(_)
          return 6.0
        end
      end

      class PopulationBomb < MultiHit
        # Process the power amplification according to potential hit amount
        # @param user [PFM::PokemonBattler]
        # @return [Float]
        def move_hit_multiplier(_)
          return 10.0
        end
      end

      register(:s_multi_hit, MultiHit, 3)
      register(:s_2hits, TwoHit, 3)
      register(:s_3hits, ThreeHit, 3)
      register(:s_triple_kick, TripleKick, 3)
      register(:s_population_bomb, PopulationBomb, 3)
      register(:s_water_shuriken, MultiHit, 3)
    end
  end
end
