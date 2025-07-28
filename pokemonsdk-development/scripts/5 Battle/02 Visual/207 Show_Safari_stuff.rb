module Battle
  class Visual
    # Show the bait or mud throw animation if Safari Battle
    # @param target_pokemon [PFM::PokemonBattler] pokemon being thrown something at
    # @param bait_mud [Symbol] :bait or :mud, depending on the player's choice
    def show_bait_mud_animation(target_pokemon, bait_mud)
      origin = battler_sprite(0, -1)
      target = battler_sprite(target_pokemon.bank, target_pokemon.position)
      @sprite = UI::ThrowingBaitMudSprite.new(origin.viewport, bait_mud)
      animation = create_throw_bait_mud_animation(@sprite, target, origin)
      animation.start
      @animations << animation
      wait_for_animation
    end

    private

    # Create the throw bait or mud animation
    # @param sprite [UI::ThrowingBallSprite]
    # @param target [Sprite]
    # @param origin [Sprite]
    # @return [Yuki::Animation::TimedAnimation]
    def create_throw_bait_mud_animation(sprite, target, origin)
      ya = Yuki::Animation
      sprite.set_position(origin.x - sprite.trainer_offset, origin.y - sprite.trainer_offset)

      animation = ya.scalar_offset(0.5, sprite, :y, :y=, 0, -64, distortion: :SQUARE010_DISTORTION)
      animation.parallel_play(ya.move(0.5, sprite, sprite.x, sprite.y, target.x, target.y - sprite.offset_y))
      animation.parallel_play(ya.scalar(0.5, sprite, :throw_progression=, 0, 1))
      animation.parallel_play(ya.se_play(*sending_ball_se))
      animation.parallel_play(origin.throw_bait_mud_animation)
      animation.play_before(ya.wait(0.4))
      animation.play_before(ya.send_command_to(sprite, :dispose))

      return animation
    end
  end
end
