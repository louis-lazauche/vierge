module UI

  class StatAnimation < SpriteSheet
    include RecenterSprite

    COLUMNS = 12
    ROWS = 10
    MAX_INDEX = COLUMNS * ROWS - 1

    # Create a new StatAnimation
    # @param viewport [Viewport]
    # @param amount [Integer]
    # @param z [Integer]
    # @param bank [Integer]
    def initialize(viewport, amount, z, bank)
      super(viewport, COLUMNS, ROWS)
      @amount = amount
      @bank = bank
      self.bitmap = RPG::Cache.animation(@amount > 0 ? 'stat_up' : 'stat_down')
      self.zoom = zoom_value
      self.sx = 0
      self.sy = 0
      self.z = z
      set_origin(width / 2, height)
      Graphics.sort_z
    end

    # Function that change the sprite according to the progression of the animation
    # @param progression [Float]
    def animation_progression=(progression)
      index = (progression * MAX_INDEX).floor.clamp(0, MAX_INDEX)

      self.sx = index % COLUMNS
      self.sy = index / COLUMNS
    end

    # return the zoom value for the bitmap
    # @return [Integer]
    def zoom_value
      return 1 if battle_3d? && !enemy?

      return 0.5
    end

    # Return the x offset for the Stat Animation
    # @param [Integer]
    def x_offset
      return -2 + Graphics.width / 2 if battle_3d?

      return -2
    end

    # Return the y offset for the Stat Animation
    # @param [Integer]
    def y_offset
      return 10 + Graphics.height / 2 if battle_3d?

      return 10
    end

    # Tell which type of battle it is
    # @return [Boolean]
    def battle_3d?
      return Battle::BATTLE_CAMERA_3D
    end

    # Tell if the Animation is from the enemy side
    # @return [Boolean]
    def enemy?
      return @bank == 1
    end
  end
end
