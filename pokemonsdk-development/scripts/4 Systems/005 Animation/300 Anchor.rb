module Yuki
  module Animation
    # Class brining target to an anchor position (dynamically)
    class Anchor < TimedAnimation
      # Create a new Anchor
      # @param on [ShaderedSprite | Symbol] object getting anchored
      # @param to [ShaderedSprite | Symbol] object to anchor to
      # @param z_offset [Integer] offset z while anchoring to another object
      def initialize(on, to, z_offset)
        super(0, :UNICITY_DISTORTION, :SCENE_TIME_SOURCE)
        @on_param = on
        @to_param = to
        @z_offset_param = z_offset
      end

      def start(begin_offset = 0)
        super
        @z_offset = resolve(@z_offset_param)
      end

      # Anchor animations are always done
      def done?
        return true
      end

      def update
        update_internal
        @parallel_animations.each(&:update)
        return unless @parallel_animations.all?(&:done?)
        return @sub_animation&.update
      end

      private

      def update_internal
        on = (@on ||= resolve(@on_param))
        to = (@to ||= resolve(@to_param))
        on.set_position(to.x, to.y)
        on.z = to.z + @z_offset
      end
    end

    module_function

    # @param on [ShaderedSprite | Symbol] object getting anchored
    # @param to [ShaderedSprite | Symbol] object to anchor to
    # @param z_offset [Integer] offset z while anchoring to another object
    def anchor(on, to, z_offset = 0)
      return Anchor.new(on, to, z_offset)
    end
  end
end
