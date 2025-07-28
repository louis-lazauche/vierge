module Battle
  module AI
    class MoveHeuristicBase
      class SleepTalk < MoveHeuristicBase
        # Create a new Sleep Talk Heuristic
        def initialize
          super(true, true, true)
        end

        # Compute the heuristic
        # @param move [Battle::Move]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param ai [Battle::AI::Base]
        # @return [Float]
        def compute(move, user, target, ai)
          return ai.scene.logic.generic_rng.rand(0.10) + 0.60 if user.has_ability?(:comatose) # 0.60 ~ 0.70

          low_odd = ai.scene.logic.generic_rng.rand(0.25) + 0.25 # 0.25 ~ 0.50
          return low_odd unless user.asleep? && user.sleep_turns < 3

          return 1.0
        end
      end

      class Snore < MoveHeuristicBase
        # Compute the heuristic
        # @param move [Battle::Move]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param ai [Battle::AI::Base]
        # @return [Float]
        def compute(move, user, target, ai)
          low_odd = ai.scene.logic.generic_rng.rand(0.25) + 0.25 # 0.25 ~ 0.50
          return super if user.has_ability?(:comatose)
          return low_odd unless user.asleep? && user.sleep_turns < 3

          return Math.sqrt(super)
        end
      end

      class DreamEater < MoveHeuristicBase
        # Compute the heuristic
        # @param move [Battle::Move]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param ai [Battle::AI::Base]
        # @return [Float]
        def compute(move, user, target, ai)
          return super if target.has_ability?(:comatose) || (target.asleep? && target.sleep_turns < 3)

          low_odd = ai.scene.logic.generic_rng.rand(0.25) + 0.25 # 0.25 ~ 0.50
          return low_odd
        end
      end

      class Nightmare < MoveHeuristicBase
        # Create a new Nightmare Heuristic
        def initialize
          super(true, true, true)
        end

        # Compute the heuristic
        # @param move [Battle::Move]
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param ai [Battle::AI::Base]
        # @return [Float]
        def compute(move, user, target, ai)
          low_odd = ai.scene.logic.generic_rng.rand(0.25) + 0.25 # 0.25 ~ 0.50
          high_odd = 1.0 - target.sleep_turns / 8.0 # 0.625 ~ 1.00
          # Base status move heuristic if the target has Comatose
          return Math.exp((user.last_sent_turn - $game_temp.battle_turn + 1) / 10.0) * 0.85 if target.has_ability?(:comatose)

          return target.asleep? ? high_odd : low_odd
        end
      end

      register(:s_sleep_talk, SleepTalk, 2)
      register(:s_snore, Snore, 2)
      register(:s_dream_eater, DreamEater, 2)
      register(:s_nightmare, Nightmare, 3)
    end
  end
end
