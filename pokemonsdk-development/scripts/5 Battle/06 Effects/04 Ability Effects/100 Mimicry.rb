module Battle
  module Effects
    class Ability
      class Mimicry < Ability
        # Types based on terrains
        TYPES = {
          psychic_terrain: :psychic,
          misty_terrain: :fairy,
          grassy_terrain: :grass,
          electric_terrain: :electric
        }

        # Function called when a Pokemon has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Pokemon that is switched out
        # @param with [PFM::PokemonBattler] Pokemon that is switched in
        def on_switch_event(handler, who, with)
          return if with != @target || @logic.field_terrain == :none

          change_on_active_terrain(handler, @target, @logic.field_terrain)
        end

        # Function called after the terrain was changed
        # @param handler [Battle::Logic::FTerrainChangeHandler]
        # @param fterrain_type [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        # @param last_fterrain [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        def on_post_fterrain_change(handler, fterrain_type, last_fterrain)
          if fterrain_type == :none
            @target.restore_types
            handler.scene.visual.show_ability(@target)
            handler.scene.display_message_and_wait(original_type_message(@target))
          else
            change_on_active_terrain(handler, @target, fterrain_type)
          end
        end

        private

        # Function for changing to a new type due to an active terrain
        # @param handler [Battle::Logic::FTerrainChangeHandler]
        # @param target [PFM::PokemonBattler]
        # @param fterrain_type [Symbol] :none, :electric_terrain, :grassy_terrain, :misty_terrain, :psychic_terrain
        def change_on_active_terrain(handler, target, fterrain_type)
          new_type = TYPES[fterrain_type]
          return if new_type.nil?

          target.change_types(data_type(new_type).id)
          handler.scene.visual.show_ability(target)
          handler.scene.display_message_and_wait(changed_type_message(target, new_type))
        end

        # Message text for changing to a new type.
        # @param target [PFM::PokemonBattler]
        # @param new_type [Integer] ID of the new type
        # @return [String]
        def changed_type_message(target, new_type)
          return parse_text_with_pokemon(59, 1212, target, '[VAR 0103(0001)]' => data_type(new_type).name)
        end

        # Message text for reverting to the original type.
        # @param target [PFM::PokemonBattler]
        # @return [String]
        def original_type_message(target)
          return parse_text_with_pokemon(59, 2002, target)
        end
      end
      register(:mimicry, Mimicry)
    end
  end
end
