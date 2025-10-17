module Battle
  module Effects
    class Ability
      class SheerForce < Ability
        # If the ability is activated or not
        # @return [Boolean]
        attr_writer :activated

        # Create a new Sheer Force effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # If Sheer Force is currently activated
        # @return [Boolean]
        def activated?
          return @activated
        end
        alias activated activated?

        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return if target == @target
          return unless @activated
          return unless skill

          return handler.prevent_change
        end

        # Function called when a stat_increase_prevention is checked
        # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the stat increase cannot apply
        def on_stat_increase_prevention(handler, stat, target, launcher, skill)
          return if target != @target
          return unless @activated
          return unless skill

          return handler.prevent_change
        end

        # Function called when a stat_decrease_prevention is checked
        # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the stat decrease cannot apply
        def on_stat_decrease_prevention(handler, stat, target, launcher, skill)
          return if target == @target
          return unless @activated
          return unless skill

          return handler.prevent_change
        end

        # Give the move base power mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def base_power_multiplier(user, target, move)
          return 1 unless can_be_boosted?(user, target, move)

          log_data('Base Power increased by 1.3 after Sheer Force activation')
          @activated = true

          return 1.3
        end

        # Get the name of the effect
        # @return [Symbol]
        def name
          return :sheer_force
        end

        private

        # The status that can be boosted by Sheer Force
        # @return [Array<Symbol>]
        STATUS_DB_SYMBOL = %i[poison toxic sleep freeze paralysis burn flinch].freeze
        # Check if the move can be boosted by Sheer Force
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move]
        # @return [Boolean] true if the move can be boosted by Sheer Force, false otherwise
        def can_be_boosted?(user, target, move)
          return false if move.status?

          if move.battle_stage_mod.any?
            only_positive = move.battle_stage_mod.all? { |battle_stage| battle_stage.count.positive? }
            only_negative = move.battle_stage_mod.all? { |battle_stage| battle_stage.count.negative? }

            return true if move.is_a?(Battle::Move::SelfStat) && only_positive
            return true if !move.is_a?(Battle::Move::SelfStat) && only_negative
          end

          if move.status_effects.any?
            all_valid_status = move.status_effects.all? { |status_effect| STATUS_DB_SYMBOL.include?(status_effect.status) }
            return true if !move.is_a?(Battle::Move::SelfStatus) && all_valid_status
          end

          return false
        end
      end

      register(:sheer_force, SheerForce)
    end
  end
end
