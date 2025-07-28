module BattleUI
  # Class that allows the player to make the choice of the action he wants to do during a Safari battle
  class PlayerChoiceSafari < PlayerChoice
    include UI
    include PlayerChoiceAbstraction
    # Create the 4 main action buttons
    def create_buttons
      # @type [Array<Button>]
      @buttons = 4.times.map do |i|
        add_sprite(*BUTTON_COORDINATE[i], NO_INITIAL_IMAGE, i, type: ButtonSafari)
      end
    end

    # Create the sub-choice buttons
    def create_sub_choice
      @sub_choice = add_sprite(0, 0, NO_INITIAL_IMAGE, @scene, self, type: SubChoiceSafari)
    end

    # Validate the player choice
    def validate
      bounce_button
      case @index
      when 0
        success = choice_safari_ball
      when 1
        success = choice_bait
      when 2
        success = choice_mud
      when 3
        success = choice_flee
      else
        return
      end
      return show_switch_choice_failure unless success

      $game_system.se_play($data_system.decision_se)
    end

    # Buttons of the player choices, modified for Safari battles
    class ButtonSafari < PlayerChoice::Button
      # Get the filename of the sprite
      # @return [String]
      def image_filename
        return 'battle/actions_safari_'
      end
    end

    # UI element showing the sub_choice and interacting with the parent choice, modified for Safari battles
    class SubChoiceSafari < PlayerChoice::SubChoice
      # Action triggered when pressing Y
      def action_y
        $scene.message_window.wait_input = true
        $scene.display_message_and_wait(parse_text(71, 19, '[VAR BALLS]' => $bag.item_quantity(:safari_ball).to_s))
      end

      # Action triggered when pressing X
      def action_x
        $game_system.se_play($data_system.buzzer_se)
        return
      end
    end
  end
end
