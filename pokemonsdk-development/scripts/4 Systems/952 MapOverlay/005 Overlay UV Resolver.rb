module PFM
  class MapOverlay
    # Class responsive of resolving target uv coordinates for the shaders used in MapOverlay
    class UVResolver
      # Create a new UVResolver
      # @param source_coordinates [Array<Integer>, Symbol] (:game_player for player's coordinates)
      # @param coordinate_type [Symbol] Must be :tile (defined for later uses)
      def initialize(source_coordinates, coordinate_type = :tile)
        @source_coordinates = source_coordinates
        @coordinate_type = coordinate_type
        # Stored in initialize as it's less likely that the game swap tilemap size in the same map
        @tilesize = Configs.display.tilemap_settings.tilemap_class == 'Yuki::Tilemap16px' ? 16 : 32
        @zoom = Configs.display.window_scale.to_f
      end

      # Resolve the uv coordinates
      # @param screen_size [Array<Float>] size of the screen
      # @param origin [Object] object allowing the find the origin of the screen in its own coordinate space
      # @return [Array<Float>]
      def resolve(screen_size, origin)
        sx, sy = coordinates_relative_to_origin(origin)
        zoom = @zoom

        return [
          sx / (screen_size.first * zoom),
          sy / (screen_size.last * zoom)
        ]
      end

      private

      # Get the coordinates relative to origin
      # @param origin [Object]
      # @return [Array<Float>]
      def coordinates_relative_to_origin(origin)
        return [0, 0] if @coordinate_type != :tile || !origin.is_a?(Game_Character)

        src_x, src_y = source_coordinates
        dx = src_x - origin.x
        dy = origin.y - src_y - 0.5 # The shader makes the y coordinate go in the other direction apparently
        screen_factor = @tilesize * @zoom
        return [
          dx * screen_factor + origin.screen_x,
          dy * screen_factor + origin.screen_y
        ]
      end

      # Get the source coordinates
      # @return [Array<Float>]
      def source_coordinates
        return [$game_player.x, $game_player.y] if @source_coordinates == :game_player

        return @source_coordinates
      end
    end
  end
end
