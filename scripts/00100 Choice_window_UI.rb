# monkeypatch : sépare boutons / textes pour ChoiceWindow avec curseur aligné
module Yuki
  class ChoiceWindow < Window
    # garde l'initialize d'origine, puis ajoute nos piles séparées
    alias_method :_yuki_choice_init, :initialize
    def initialize(width, choices, viewport = nil)
      _yuki_choice_init(width, choices, viewport)

      # piles séparées
      @button_stack = UI::SpriteStack.new(self)
      if defined?(@texts) && @texts
        @texts.dispose if @texts.respond_to?(:dispose)
      end
      @texts = UI::SpriteStack.new(self)

      # recalcul du curseur après création des boutons
      refresh
    end

    # rebuild complet : boutons + textes
    alias_method :_yuki_choice_refresh, :refresh
    def refresh
      @button_stack&.dispose
      @texts&.dispose
      @button_stack = UI::SpriteStack.new(self)
      @texts = UI::SpriteStack.new(self)

      max_width = 0
      total_height = 0

      @choices.each_index do |i|
        text = PFM::Text.parse_string_for_messages(@choices[i]).dup
        text.gsub!(/\\[Cc]\[([0-9]+)\]/) { @colors[i] = translate_color($1.to_i); nil }
        text.gsub!(/\\d\[(.*),(.*)\]/) { $daycare.parse_poke($1.to_i, $2.to_i) }

        real_width, btn_h = add_choice_text(text, i)
        max_width = real_width if real_width > max_width
        total_height += btn_h
      end

      # ajustement largeur/hauteur fenêtre
      if @autocalc_width
        self.width = max_width + window_builder[4] + window_builder[-2] + cursor_rect.width + cursor_rect.x
        self.width += 10 if current_windowskin[0, 2].casecmp?('m_')
      end
      self.height = total_height + window_builder[1] + window_builder[-1]

      # ajuste largeur textes
      @texts.stack.each { |elt| elt.width = max_width if elt.is_a?(Text) }

      # 🔑 positionne le curseur sur le bouton courant
      define_cursor_rect
    end

    # redéfinit le rect du curseur sur le bouton courant
    def define_cursor_rect
      return unless @button_stack && @button_stack.stack[@index]
      btn = @button_stack.stack[@index]
      # Le curseur se place sur le bouton mais on ne touche pas aux textes
      cursor_rect.set(0, btn.y, (cursorskin.width * btn.zoom_x).to_i, (cursorskin.height * btn.zoom_y).to_i)
    end

    # ajoute un bouton + texte centré
    # ajoute un bouton + texte centré sur le bouton
    def add_choice_text(text, i)
      # si c'est le bouton "Retour", on prend une autre image
      btn_graphic = text == text_get(22, 7) ? 'choice_back' : 'choice_icon'
      btn = @button_stack.add_sprite(0, 0, RPG::Cache.windowskin(btn_graphic))

      btn_w = (btn.bitmap.width  * btn.zoom_x).to_i
      btn_h = (btn.bitmap.height * btn.zoom_y).to_i
      btn.set_position(0, i * btn_h)

      # Texte centré verticalement sur le bouton
      text_y = btn.y + (btn_h - default_line_height) / 2
      text_obj = @texts.add_text(13, text_y, btn_w, default_line_height, text, 0, color: @colors[i], sizeid:9)
      text_obj.z = btn.z + 1

      return btn_w, btn_h
    end




    # déplacement curseur
    def update_cursor_up
      if @index == 0
        (@choices.size - 1).times { update_cursor_down }
        return
      end
      @index -= 1
      define_cursor_rect
      cool_down
    end

    def update_cursor_down
      @index += 1
      @index = 0 if @index >= @choices.size
      define_cursor_rect
      cool_down
    end

    # dispose piles correctement
    alias_method :_yuki_choice_dispose, :dispose
    def dispose
      @button_stack&.dispose
      @texts&.dispose
      _yuki_choice_dispose
    end

    # override windowskin vide
    def windowskin=(v)
      super(RPG::Cache.windowskin("empty"))
    end
  end
end

# helper pour construire la fenêtre
module PFM
  class Choice_Helper
    def build_choice_window(viewport, x, y, width, align_right)
      choice_list = @choices.collect { |c| c[:text] }
      window = @class.new(width, choice_list, viewport)
      #position des boutons
      window.set_position(x - window.width - 15, y - window.height + 38)
      window.z = viewport ? viewport.z : 1000

      @choices.each_with_index do |c, i|
        if c[:disable_detect]&.call(*c[:args])
          window.colors[i] = window.get_disable_color
        elsif c[:color]
          window.colors[i] = c[:color]
        end
      end

      window.refresh
      Graphics.sort_z
      return window
    end
  end
end


module GamePlay
  module DisplayMessage
    # Version alternative : n’affiche pas de message, mais gère les choix
    def display_choice_only(start = 1, *choices, &block)
      raise ScriptError, MESSAGE_ERROR unless @message_window
      raise ScriptError, MESSAGE_PROCESS_ERROR unless @message_done_processing && can_display_message_be_called?

      block ||= @__display_message_proc
      @message_done_processing = false
      @message_choice = nil
      @still_in_display_message = true

      # On ne touche pas à $game_temp.message_text → pas de MessageWindow
      if choices.any?
        $game_temp.choice_max = choices.size
        $game_temp.choice_cancel_type = choices.size
        $game_temp.choice_proc = proc { |i| @message_choice = i }
        $game_temp.choice_start = start
        $game_temp.choices = choices
      else
        @message_done_processing = true
      end

      until @message_done_processing
        message_update_scene
        @base_ui&.update  # 🔑 show_win_text continue à s’afficher
        block&.call
      end
      Graphics.update
      return @message_choice
    ensure
      @still_in_display_message = false
    end
  end
end



# -------------------------------------------------------------------------------
## PAS TRES OPTI - REGARDER DU COTE DE LAYOUT ET WINDOW
# -------------------------------------------------------------------------------

module LogMessageWidthBeforeParsing
  def parse_and_show_new_message
    log_info("message_width=#{message_width}; viewport_width=#{viewport.rect.width}")
    super
  end
end

UI::Message::Window.prepend(LogMessageWidthBeforeParsing)

class UI::Message::Window
  alias update_old update  # Sauvegarde l'ancienne méthode update
  def update
    self.y = 145  # Nouveau comportement
    update_old   # Appel de l'ancienne méthode update
  end
end

module UI
  module Message
    # Module defining the Message layout
    module Layout
      def window_width
        252
      end

      # Return the window height
      def window_height
        44 if windowskin
      end

      # Return the default horizontal margin
      # @return [Integer]
      def default_horizontal_margin
        return 2
      end
    end
  end
end

module Battle
  class Scene
    # Message Window of the Battle
    class Message < UI::Message::Window
      # Retrieve the current window_builder
      # @return [Array]
      def current_window_builder
        return [16, 10, 288, 30, 16, 10] if current_windowskin == WINDOW_SKIN

        return super
      end
    end
  end
end
# -------------------------------------------------------------------------------
# -------------------------------------------------------------------------------