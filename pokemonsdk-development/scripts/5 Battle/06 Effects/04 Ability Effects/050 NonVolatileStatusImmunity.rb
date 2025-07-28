module Battle
  module Effects
    class Ability
      # Base class for an ability that prevents and cures a non-volatile status condition on the Creature.
      class NonVolatileStatusImmunityBase < Ability
        # Function called when a Creature has actually switched with another one
        # @param handler [Battle::Logic::SwitchHandler]
        # @param who [PFM::PokemonBattler] Creature that is switched out
        # @param with [PFM::PokemonBattler] Creature that is switched in
        def on_switch_event(handler, who, with)
          return unless with == @target
          return unless curable_status?(with)

          handler.scene.visual.show_ability(with)
          handler.logic.status_change_handler.status_change(:cure, with)
        end

        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          return unless target == @target
          return unless status_to_kill.include?(status)
          return unless launcher&.can_be_lowered_or_canceled?

          return handler.prevent_change do
            handler.scene.visual.show_ability(target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, text_id, target))
          end
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return unless curable_status?(@target)

          # There are ways to bypass the ability's status prevention while it is active.
          # The ability should cure the user's status immediately.
          scene.visual.show_ability(@target)
          logic.status_change_handler.status_change(:cure, @target)
        end

        private

        # Non-volatile status conditions that should be prevented or cured
        # @return [Array<Symbol>] :poison, :toxic, :sleep, :freeze, :paralysis, :burn
        def status_to_kill
          raise 'This method should be implemented in the subclass'
        end

        # ID of the text in the file to use for the status prevention message
        # @return [Integer]
        def text_id
          raise 'This method should be implemented in the subclass'
        end

        # Checks if the Creature has a non-volatile status condition this ability can cure
        # @param target [PFM::PokemonBattler]
        # @return [Boolean]
        def curable_status?(target)
          return status_to_kill.any? { |s| target.status == Configs.states.ids[s] }
        end
      end

      class Immunity < NonVolatileStatusImmunityBase
        private

        # Non-volatile status conditions that should be prevented or cured
        # @return [Array<Symbol>] :poison, :toxic, :sleep, :freeze, :paralysis, :burn
        def status_to_kill
          return %i[poison toxic]
        end

        # ID of the text in the file to use for the status prevention message
        # @return [Integer]
        def text_id
          return 252
        end
      end

      class Insomnia < NonVolatileStatusImmunityBase
        private

        # Non-volatile status conditions that should be prevented or cured
        # @return [Array<Symbol>] :poison, :toxic, :sleep, :freeze, :paralysis, :burn
        def status_to_kill
          return %i[sleep]
        end

        # ID of the text in the file to use for the status prevention message
        # @return [Integer]
        def text_id
          return 318
        end
      end

      class Limber < NonVolatileStatusImmunityBase
        private

        # Non-volatile status conditions that should be prevented or cured
        # @return [Array<Symbol>] :poison, :toxic, :sleep, :freeze, :paralysis, :burn
        def status_to_kill
          return %i[paralysis]
        end

        # ID of the text in the file to use for the status prevention message
        # @return [Integer]
        def text_id
          return 285
        end
      end

      class MagmaArmor < NonVolatileStatusImmunityBase
        private

        # Non-volatile status conditions that should be prevented or cured
        # @return [Array<Symbol>] :poison, :toxic, :sleep, :freeze, :paralysis, :burn
        def status_to_kill
          return %i[freeze]
        end

        # ID of the text in the file to use for the status prevention message
        # @return [Integer]
        def text_id
          return 300
        end
      end

      class WaterVeil < NonVolatileStatusImmunityBase
        private

        # Non-volatile status conditions that should be prevented or cured
        # @return [Array<Symbol>] :poison, :toxic, :sleep, :freeze, :paralysis, :burn
        def status_to_kill
          return %i[burn]
        end

        # ID of the text in the file to use for the status prevention message
        # @return [Integer]
        def text_id
          return 270
        end
      end

      register(:immunity, Immunity)
      register(:insomnia, Insomnia)
      register(:vital_spirit, Insomnia)
      register(:limber, Limber)
      register(:magma_armor, MagmaArmor)
      register(:water_veil, WaterVeil)
    end
  end
end
