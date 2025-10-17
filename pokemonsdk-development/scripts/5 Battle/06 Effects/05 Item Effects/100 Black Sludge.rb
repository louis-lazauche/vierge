module Battle
  module Effects
    class Item
      class BlackSludge < Item
        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return heal(logic, scene, @target) if @target.type_poison?

          hurt(logic, scene, @target)
        end

        private

        # @param logic [Battle::Logic]
        # @param scene [Battle::Scene]
        # @param target [PFM::PokemonBattler]
        def heal(logic, scene, target)
          return unless logic.damage_handler.can_heal?(target)

          scene.visual.show_item(target)
          logic.damage_handler.heal(target, target.max_hp / 16)
        end

        # @param logic [Battle::Logic]
        # @param scene [Battle::Scene]
        # @param target [PFM::PokemonBattler]
        def hurt(logic, scene, target)
          return if target.has_ability?(:magic_guard)

          scene.display_message_and_wait(parse_text_with_pokemon(19, 1044, target, PFM::Text::ITEM2[1] => target.item_name))
          logic.damage_handler.damage_change((target.max_hp / 8).clamp(1, Float::INFINITY), target)
        end
      end
      register(:black_sludge, BlackSludge)
    end
  end
end
