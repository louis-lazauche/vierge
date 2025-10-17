module Battle
  module Actions
    # Class describing the usage of switching out a Pokemon
    class Shift < Base
      # Get the Pokemon who initiated the shifting
      # @return [PFM::PokemonBattler]
      attr_reader :launcher

      # Create a new shift action
      # @param scene [Battle::Scene]
      # @param launcher [PFM::PokemonBattler] Pokemon who initiated the shifting
      def initialize(scene, launcher)
        super(scene)
        @launcher = launcher
      end

      # Compare this action with another
      # @param other [Base] other action
      # @return [Integer]
      def <=>(other)
        return (other <=> self) * -1 if other.is_a?(Attack)
        return Shift.from(other).launcher.spd <=> @launcher.spd if other.is_a?(Shift)

        return 1
      end

      # Get the priority of the move
      # @return [Integer]
      def priority
        return 0
      end

      # Execute the action
      def execute
        return if @launcher.hp <= 0

        visual = @scene.visual
        show_shifting_message

        # Launcher goes inside the pokeball
        launcher_sprite = visual.battler_sprite(@launcher.bank, @launcher.position)
        launcher_sprite.go_out
        visual.hide_info_bar(@launcher)
        wait_for(launcher_sprite, visual)
        # With goes inside the pokeball
        with = @scene.logic.get_middle_battler(@launcher.bank)
        with_sprite = visual.battler_sprite(with.bank, with.position)
        if with&.alive?
          with_sprite.go_out
          visual.hide_info_bar(with)
          wait_for(with_sprite, visual)
        end

        # Logically shifting the Pokemon
        @scene.logic.shift_battlers(@launcher, with)
        visual.shift_battler_sprite(@launcher, with)

        # Launcher goes back out
        launcher_sprite.pokemon = @launcher
        launcher_sprite.visible = false # Ensure there's no glitch with animation (the animation sets visible :))
        launcher_sprite.go_in
        visual.show_info_bar(@launcher)
        wait_for(launcher_sprite, visual)
        # With goes back out
        with_sprite.pokemon = with
        with_sprite.visible = false # Ensure there's no glitch with animation (the animation sets visible :))
        if with&.alive?
          with_sprite.go_in
          visual.show_info_bar(with)
        else
          # Still need to refresh the bar so that it's not linked to the launcher anymore
          visual.refresh_info_bar(with)
        end
        wait_for(with_sprite, visual)
      end

      private

      # Wait for the sprite animation to be done
      # @param sprite [#done?]
      # @param visual [Battle::Visual]
      def wait_for(sprite, visual)
        until sprite.done?
          visual.update
          Graphics.update
        end
      end

      # Show the shifting message
      def show_shifting_message
        return if @launcher.dead?

        msg_id = @launcher.from_party? ? 316 : 318
        message = parse_text(59, msg_id, { PFM::Text::PKNICK[0] => @launcher.given_name })
        @scene.display_message_and_wait(message)
      end
    end
  end
end
