module UI
  # Sprite responsive of showing the sprite of the bait or mud we throw at a Pokemon
  class ThrowingBaitMudSprite < SpriteSheet
    # Create a new ThrowingBaitMudSprite
    # @param viewport [Viewport]
    # @param bait_mud [Symbol] :bait or :mud, depending on the player's choice
    def initialize(viewport, bait_mud)
      super(viewport, 1, 7)
      resolve_image(bait_mud)
      self.sy = 0
    end

    # Function that adjust the sy depending on the progression of the "throw" animation
    # @param progression [Float]
    def throw_progression=(progression)
      self.sy = (progression * 6).floor.clamp(0, 6)
    end

    # Get the offset y in order to make it the same position as the Pokemon sprite
    # @return [Integer]
    def offset_y
      return 8
    end

    # Get the offset y in order to make it look like being in trainer's hand
    # @return [Integer]
    def trainer_offset
      return -80 if Battle::BATTLE_CAMERA_3D

      return 40
    end

    private

    # Resolve the sprite image
    # @param bait_mud [Symbol] :bait or :mud, depending on the player's choice
    def resolve_image(bait_mud)
      self.bitmap = RPG::Cache.ball(bait_mud == :bait ? 'ball_s1' : 'ball_s2')
      set_origin(width / 2, height / 2)
    end
  end
end
