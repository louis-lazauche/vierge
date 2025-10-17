module Battle
  module Effects
    class Item
      class RedOrb < Item
        # Function called when a creature has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] creature that is switched out
        # @param with [PFM::PokemonBattler] creature that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target
          return unless with.db_symbol == creature_symbol
          return if with.form == 1

          with.primal_evolve
          # Missing Primal Reversion animation
          # handler.scene.visual.show_primal_animation(creature)
          handler.scene.visual.show_switch_form_animation(with)
          handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 1241, with))
          with.ability_effect.on_switch_event(handler.logic.switch_handler, with, with)
        end

        # creature that can undergo primal reversion
        # @return [Symbol] creature db_symbol
        def creature_symbol
          return :groudon
        end
      end
      register(:red_orb, RedOrb)

      class BlueOrb < RedOrb
        # Creature that can undergo primal reversion
        # @return [Symbol] creature db_symbol
        def creature_symbol
          return :kyogre
        end
      end
      register(:blue_orb, BlueOrb)
    end
  end
end
