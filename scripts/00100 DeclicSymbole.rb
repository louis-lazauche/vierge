module Battle
  module Effects
    class Ability
      class DeclicSymbole < Ability
        # Function called when we try to use a move as the user (returns :prevent if user fails)
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        # @return [:prevent, nil] :prevent if the move cannot continue
        def on_move_prevention_user(user, targets, move)
          return if user != @target
          if move.real_base_power(user, targets.first) > 0
            colibris
          elsif move.status?
            condor
          end
        end
        private
        # Apply colibris Form
        def colibris
          original_form = @target.form
          @target.form_calibrate(:colibris)
          apply_change_form(252) unless @target.form == original_form
        end
        # Apply condor Form        
        def condor
          original_form = @target.form
          @target.form_calibrate
          apply_change_form(253) unless @target.form == original_form
        end
        # Apply change form        
        # @param text_id [Integer] id of the message text
        def apply_change_form(text_id)
          @logic.scene.visual.show_ability(@target)
          @logic.scene.visual.show_switch_form_animation(@target)
          @logic.scene.visual.wait_for_animation
          @logic.scene.display_message_and_wait(parse_text(18, text_id))
        end
      end
      register(:declic_symbole, DeclicSymbole)
    end
  end
end

module PFM
  class Pokemon
   FORM_CALIBRATE[:sigilyph] = proc { |reason| @form = reason == :colibris ? 0 : 1 }
  end
end