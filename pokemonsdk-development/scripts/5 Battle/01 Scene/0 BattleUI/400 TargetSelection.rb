module BattleUI
  # UI element responsive of letting the Player choose which creature to aim
  class TargetSelection < UI::SpriteStack
    include TargetSelectionAbstraction
    # Tell if moves with no choice should not show that UI
    SKIP_NO_CHOICE_SKILL = true
    # Create a new TargetSelection
    # @param viewport [Viewport]
    # @param launcher [PFM::PokemonBattler]
    # @param move [Battle::Move]
    # @param logic [Battle::Logic]
    def initialize(viewport, launcher, move, logic)
      super(viewport)
      initialize_data(launcher, move, logic)
      @animation_handler = Yuki::Animation::Handler.new
      create_sprites
      update_cursor(true) if @allow_selection
    end

    # Update the Window cursor
    def update
      super
      return @animation_handler.update unless @animation_handler.done?
      return if validated?
      return validate if Input.trigger?(:A) || Mouse.trigger?(:LEFT)
      return cancel if Input.trigger?(:B) || Mouse.trigger?(:RIGHT)
      return unless @allow_selection

      last_index = @index
      update_key_index
      update_mouse_index
      update_cursor if last_index != @index && @allow_selection
    end

    private

    def update_key_index
      if Input.repeat?(:UP)
        @index = (@index - @row_size) % @buttons.size
      elsif Input.repeat?(:RIGHT)
        @index = (@index + 1) % @buttons.size
      elsif Input.repeat?(:LEFT)
        @index = (@index - 1) % @buttons.size
      elsif Input.repeat?(:DOWN)
        @index = (@index + @row_size) % @buttons.size
      end
    end

    def update_mouse_index
      return unless Mouse.moved

      @buttons.each_with_index do |button, index|
        break @index = index if button.simple_mouse_in?
      end
    end

    def create_sprites
      add_background('battle/background')
      @buttons = @mons.map.with_index do |pokemon, index|
        push_sprite(Button.new(@viewport, index, @row_size, pokemon, @launcher, @move, @targets.include?(pokemon)))
      end
    end

    # Validate the player choice
    def validate
      if choose_target
        $game_system.se_play($data_system.decision_se)
      else
        $game_system.se_play($data_system.buzzer_se)
      end
    end

    # Cancel the player choice
    def cancel
      choice_cancel
      $game_system.se_play($data_system.cancel_se)
    end

    # Update the cursor position
    # @param silent [Boolean] if the cursor se should not be played
    def update_cursor(silent = false)
      return finalize_cursor_update(false) if silent

      create_cursor_move_animation
    end

    # Create the cursor move animation
    def create_cursor_move_animation
      # @type [Cursor]
      cursor = @buttons.find(&:selected).cursor
      selected_cursor = @buttons[@index].cursor
      animation = Yuki::Animation.move(0.2, cursor, cursor.x, cursor.y, selected_cursor.origin_x, selected_cursor.origin_y)
      animation.play_before(Yuki::Animation.send_command_to(self, :finalize_cursor_update, true))
      animation.start
      @animation_handler[:cursor_move] = animation
    end

    # Finalize the cursor update
    def finalize_cursor_update(play_sound)
      @buttons.each_with_index { |button, index| button.selected = @index == index }
      $game_system.se_play($data_system.cursor_se) if play_sound
    end

    class << self
      # Tell if the UI can be shown or not
      # @param move [Battle::Move]
      # @param pokemon [PFM::PokemonBattler]
      # @param logic [Battle::Logic]
      # @return [Boolean]
      def cannot_show?(move, pokemon, logic)
        (move.no_choice_skill? && SKIP_NO_CHOICE_SKILL) || move.battler_targets(pokemon, logic).empty?
      end
    end

    # Button shown by the UI to get what's selected
    class Button < UI::SpriteStack
      # Get the selected state of the button
      # @return [Boolean]
      attr_reader :selected
      # Get the cursor
      # @return [Cursor]
      attr_reader :cursor
      # Get the cursor
      # @return [Cursor]
      attr_reader :row_size

      ELEMENTS_POSITION = {
        'POS_ICON' => [1, 1],
        'POS_NAME' => [41, 16],
        'POS_GENDER' => [5, 16],
        'POS_EFFICIENCY_TEXT' => [18, 35],
        'POS_CURSOR' => [-10, 12]
      }

      ELEMENTS_POSITION_3V3 = {
        'POS_ICON' => [6, 0],
        'POS_NAME' => [8, 34],
        'POS_GENDER' => [8, 38],
        'POS_EFFICIENCY_TEXT' => [1, 51],
        'POS_CURSOR' => [2, 12]
      }

      # Create a new button
      # @param viewport [Viewport]
      # @param index [Integer]
      # @param row_size [Integer]
      # @param pokemon [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @param is_target [Boolean]
      def initialize(viewport, index, row_size, pokemon, launcher, move, is_target)
        super(viewport, *process_coordinates(index, row_size))
        @row_size = row_size
        create_sprites
        @move = move
        @selected = is_target
        @is_target = is_target
        @launcher = launcher
        self.data = pokemon
      end

      # Set the selected state about the button
      # @param selected [Boolean]
      def selected=(selected)
        @selected = selected

        cursor_x_offset = @row_size < 3 ? -10 : 2
        @cursor.set_position(@x + cursor_x_offset, @y + 12)
        @cursor.register_positions
        @cursor.visible = selected
      end

      # Set the Pokemon shown
      # @param pokemon [PFM::PokemonBattler]
      def data=(pokemon)
        super(pokemon)
        self.visible = pokemon&.alive?
        unless visible
          @background.visible = true
          return
        end

        @gender.x = @name.x + @name.real_width + 5
        @icon.opacity = @is_target ? 255 : 128
        @efficiency_text.text = load_efficiency_text(pokemon)
        @efficiency_text.visible = @is_target
        self.selected = @selected
      end

      private

      def create_sprites
        @background = add_background(NO_INITIAL_IMAGE, type: Background)

        element_position = @row_size < 3 ? ELEMENTS_POSITION : ELEMENTS_POSITION_3V3
        @icon = add_sprite(*element_position['POS_ICON'], NO_INITIAL_IMAGE, false, type: UI::PokemonIconSprite)
        @name = add_text(*element_position['POS_NAME'], 0, 16, :name, color: 10, type: UI::SymText)
        @gender = add_sprite(*element_position['POS_GENDER'], NO_INITIAL_IMAGE, type: UI::GenderSprite)
        @efficiency_text = add_text(*element_position['POS_EFFICIENCY_TEXT'], 102, 16, nil.to_s, 1, color: 10)
        # @type [Cursor]
        @cursor = add_sprite(*element_position['POS_CURSOR'], 'battle/arrow', type: Cursor)

        @cursor.z = 1
        @cursor.register_positions
        @cursor.visible = false
      end

      # @param pokemon [PFM::PokemonBattler]
      # @return [String]
      def load_efficiency_text(pokemon)
        efficiency = @move.type_modifier(@launcher, pokemon)
        return ext_text(8999, 23) if efficiency >= 2
        return ext_text(8999, 24) if efficiency == 0
        return ext_text(8999, 25) if efficiency < 1

        return ext_text(8999, 22)
      end

      def process_coordinates(index, row_size)
        x = index % row_size
        y = (index / row_size)

        if row_size < 3
          return (29 - 10 * y + 141 * x), 65 + y * 58
        else
          return (3 + 105 * x), 32 + y * 104
        end
      end

      # Background of the target
      class Background < Sprite
        # Set the Pokemon shown
        # @param pokemon [PFM::PokemonBattler]
        def data=(pokemon)
          return unless pokemon

          set_bitmap(image_name(pokemon), :interface)
        end

        private

        # Get the image that should be shown by the UI
        # @param pokemon [PFM::PokemonBattler]
        def image_name(pokemon)
          suffix_3v3 = $game_temp.vs_type == 3 ? '_3v3' : ''

          return "battle/target_bar_enemy#{suffix_3v3}" if pokemon.bank != 0
          return "battle/target_bar_ally#{suffix_3v3}" unless pokemon.from_party?

          return "battle/target_bar_player#{suffix_3v3}"
        end
      end
    end
  end
end
