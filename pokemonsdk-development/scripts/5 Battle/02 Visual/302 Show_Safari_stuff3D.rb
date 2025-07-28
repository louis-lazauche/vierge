module Battle
  class Visual3D
    # Offsets for target coordinates based on type and conditions
    TARGET_COORDINATE_OFFSETS[:bait_mud] = {
      solo: [-40, 0],
      base_position_0: [-90, -77],
      base_position_1: [-28, -70]
    }

    # Show the bait or mud throw animation if Safari Battle
    # @param target_pokemon [PFM::PokemonBattler] pokemon being thrown something at
    # @param bait_mud [Symbol] :bait or :mud, depending on the player's choice
    def show_bait_mud_animation(target_pokemon, bait_mud)
      origin = battler_sprite(0, -1)
      target = battler_sprite(target_pokemon.bank, target_pokemon.position)
      @sprite = UI::ThrowingBaitMudSprite.new(origin.viewport, bait_mud)
      animation = create_throw_bait_mud_animation(@sprite, target)
      animation.start
      @animations << animation
      wait_for_animation
      start_center_animation
    end

    private

    # Create the throw ball animation
    # @param sprite [UI::ThrowingBaitMudSprite]
    # @param target [Sprite]
    # @return [Yuki::Animation::TimedAnimation]
    def create_throw_bait_mud_animation(sprite, target)
      ya = Yuki::Animation
      stop_camera
      sprite.set_position(*ball_origin_position)

      animation = throwing_animation(target, sprite, :bait_mud)
      animation.play_before(ya.wait(0.4))
      animation.play_before(ya.send_command_to(sprite, :dispose))

      return animation
    end
  end
end
