
module GamePlay
  class Bag
    # empêche le clic sur la pocket list du bas
    def update_mouse(moved)
      # return update_mouse_index if Mouse.wheel != 0
      return false if moved && update_mouse_list
      return false unless update_pocket_input

      update_mouse_scrollbar
      return update_ctrl_button_mouse
    end

    # Action related to X button (redéfinir)
    def action_x
      # play_decision_se
      # @compact_mode = (@compact_mode == :enabled ? :disabled : :enabled)
      # update_info_visibility
      # update_info
    end
        
    def update_mouse_scrollbar
      return true unless Mouse.press?(:LEFT)

      # Coordonnées de la barre
      bar_x = UI::Bag::ScrollBar::BASE_X
      bar_y = UI::Bag::ScrollBar::BASE_Y
      bar_w = 16   # largeur approximative
      bar_h = UI::Bag::ScrollBar::HEIGHT

      # Vérif clic dans le rectangle
      if Mouse.x.between?(bar_x, bar_x + bar_w) && Mouse.y.between?(bar_y, bar_y + bar_h)
        ratio = (Mouse.y - bar_y).clamp(0, bar_h).fdiv(bar_h)

        new_index = (ratio * @last_index).round.clamp(0, @last_index)

        if new_index != @index
          @index = new_index
          update_item_button_list
          update_info
          @scroll_bar.index = @index
          play_cursor_se
        end
        return false
      end

      return true
    end

    #---------------------------------------------------------------------------------------------------------------

    ACTIONS = %i[NA NA NA NA NA NA NA NA NA NA mouse_left mouse_right action_y mouse_favorite action_b action_b]

    # Action pour le control button "gauche"
    def mouse_left   # ex: mouse_left
      @socket_index ||= 0
      pockets = POCKETS_PER_MODE[@mode] || []
      return if pockets.empty?

      new_index = (@socket_index - 1) % pockets.size
      change_pocket(new_index)
      play_cursor_se
    end

    # Action du bouton Ctrl Droite
    def mouse_right   # ex: mouse_right
      @socket_index ||= 0
      pockets = POCKETS_PER_MODE[@mode] || []
      return if pockets.empty?

      new_index = (@socket_index + 1) % pockets.size
      change_pocket(new_index)
      play_cursor_se
    end

    def NA 
      # no action method
    end

    def mouse_favorite
      # todo
    end
  end
end


