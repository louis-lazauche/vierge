class Spriteset_Map
  def update_map_zoom
    if $scene.is_a?(Scene_Map) && $map_zoom_enumerator
      $scene.spriteset.map_viewport.zoom = (zoom = $map_zoom_enumerator.next)
      $map_zoom_enumerator = nil if $map_zoom_enumerator.last == zoom
    end
  end
  Hooks.register(self, :update, 'Update Map Zoom') { update_map_zoom }
end

class Interpreter

  def map_zoom(zoom_start, zoom_end, step)
    # Prevents crash due to incorrect step
    return if step == 0
    step *= -1 if (zoom_start > zoom_end && step > 0) || (zoom_start < zoom_end && step < 0)

    # Apply zoom
    $map_zoom_enumerator = zoom_start.step(zoom_end, step)
  end

end