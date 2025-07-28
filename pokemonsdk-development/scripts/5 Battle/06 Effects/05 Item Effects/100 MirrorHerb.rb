module Battle
  module Effects
    class Item
      class MirrorHerb < Item
        # Create a new item effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the item
        def initialize(logic, target, db_symbol)
          super
          @stats = []
          @activated = false
        end

        # Check if the item effect is activated
        # @return [Boolean]
        def activated?
          return @activated
        end

        # Function called when a stat_change has been applied
        # @param handler [Battle::Logic::StatChangeHandler]
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param power [Integer] power of the stat change
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Integer, nil] if integer, it will change the power
        def on_stat_change_post(handler, stat, power, target, launcher, skill)
          return if target.bank == @target.bank
          return if target.hold_item?(:mirror_herb) && target.item_effect.activated?
          return unless power > 0

          @stats << [stat, power]
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?

          deal_effect(logic, scene)
        end

        private

        # Deals the effect for Mirror Herb
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        def deal_effect(logic, scene)
          return if @stats.empty?

          @activated = true
          scene.visual.show_item(@target)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1253, @target))
          @stats.each { |stat, power| logic.stat_change_handler.stat_change_with_process(stat, power, @target) }
          logic.item_change_handler.change_item(:none, true, @target)
        ensure
          @stats.clear
          @activated = false
        end
      end

      register(:mirror_herb, MirrorHerb)
    end
  end
end
