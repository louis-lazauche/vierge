module UI
  # Button that is shown in the main menu
  class PSDKMenuButtonBase < SpriteStack
    def coordinates(index)
      # Calcul de la rangée et de la colonne
      row = index / 2   # 0,1,2
      col = index % 2   # 0,1

      # Coordonnée de départ (coin haut-gauche du bloc d’icônes)
      base_x = 2
      base_y = 24

      # Espacement entre colonnes et lignes
      col_spacing = 128  # horizontal
      row_spacing = 48  # vertical

      x = base_x + col * col_spacing
      y = base_y + row * row_spacing
      return x, y
    end


    def create_text
      add_text(49, 8, 0, 23, text.sub(PFM::Text::TRNAME[0], $trainer.name), color: 36)
    end
  end
end


module GamePlay
  # Main menu UI
  class Menu < BaseCleanUpdate

    # Create all the graphics
    def create_graphics
      create_viewport
      create_background
      create_buttons
      @clock_sprite = UI::ClockSprite.new(@viewport)
      init_entering
      create_base
      @index = -1  # <- aucun bouton sélectionné au départ

      Graphics.sort_z
    end

    def create_base
      @base_ui = UI::GenericBase.new(@viewport, button_texts)
    end

    def button_texts
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, ""]
    end

    def create_buttons
      @buttons = @image_indexes.map.with_index do |real_index, i|
        next if real_index.nil?
        klass = BUTTON_OVERWRITES[real_index]&.call || UI::PSDKMenuButtonBase
        klass.new(@viewport, real_index, i)
      end.compact

      # 🔥 Forcer l’état visuel initial : rien de sélectionné
      @buttons.each { |btn| btn.selected = false }
    end


    def action
      play_decision_se
      real_index = @image_indexes[@index]
      return unless real_index

      btn = @buttons[real_index]
      if btn
        # 🚀 Lancer le blink, puis envoyer l'action seulement à la fin
        btn.selected_gif.start_blink do
          send(ACTION_LIST[real_index])
        end
      else
        send(ACTION_LIST[real_index])
      end
    end


    # Create the background under the menu buttons
    def create_background
      # On garde le blur déjà existant
      add_disposable(@background = UI::BlurScreenshot.new(@viewport, @__last_scene))
      @background.opacity = 0

      # === TON BACKGROUND CUSTOM ===
      @menu_bg = Sprite.new(@viewport)         # créer un sprite classique
      @menu_bg.bitmap = RPG::Cache.interface('menu_background_global') # ton image dans Graphics/Pictures/menu_bg.png
      @menu_bg.z = @background.z            # juste au-dessus du blur

      add_disposable(@menu_bg) # pour être nettoyé automatiquement à la fin
    end


    # index : instance variable holding the current selected button (0..5)
    # grid_cols : number of columns (2)
    # grid_rows : number of rows (3)
    def index_changed_grid(varname, up_key, down_key, left_key, right_key, cols, max_index)
      index = instance_variable_get(varname)
      row = index / cols
      col = index % cols
      old_index = index

      if Input.repeat?(up_key) && index - cols >= 0
        index -= cols
      elsif Input.repeat?(down_key) && index + cols <= max_index
        index += cols
      elsif Input.repeat?(left_key) && col > 0
        index -= 1
      elsif Input.repeat?(right_key) && col < cols - 1 && index + 1 <= max_index
        index += 1
      end

      instance_variable_set(varname, index)
      return index != old_index
    end

    def update_buttons
      @buttons.each_with_index do |btn, i|
        if @index == -1
          # Mode "aucune sélection clavier" → laisser la souris gérer
          btn.selected = btn.simple_mouse_in?
          # si la souris en sélectionne un → on le mémorise
          @index = i if btn.selected
        else
          # Mode normal → sélection clavier
          btn.selected = (i == @index)
        end
      end
    end


    def update_inputs
      return false if @entering || @quiting

      if @index == -1
        # Pas encore de sélection → attendre interaction
        if Input.trigger?(:UP) || Input.trigger?(:DOWN) || Input.trigger?(:LEFT) || Input.trigger?(:RIGHT)
          @index = 0  # toujours premier bouton
          play_cursor_se
          update_buttons
        elsif Input.trigger?(:B)
          @quiting = true
        else
          # souris peut gérer la sélection → on met juste à jour les boutons
          update_buttons
          return true
        end
      else
        if index_changed_grid(:@index, :UP, :DOWN, :LEFT, :RIGHT, 2, @max_index)
          play_cursor_se
          update_buttons
        elsif Input.trigger?(:A)
          action
        elsif Input.trigger?(:B)
          @quiting = true
        else
          update_buttons # permet au survol souris de mettre à jour même après sélection
          return true
        end
      end
      return false
    end



    def init_indexes
      # Chaque index correspond à sa place dans la grille, nil si bouton désactivé
      @image_indexes = CONDITION_LIST.map.with_index { |cond, idx| cond.call ? idx : nil }

      # Déplacer Quit à la fin si présent
      quit_index = ACTION_LIST.index(:open_quit)
      if quit_index && @image_indexes.include?(quit_index)
        @image_indexes.delete(quit_index)
        @image_indexes << quit_index
      end

      # MAJ max_index pour navigation
      @max_index = @image_indexes.compact.size - 1
    end



    clear_previous_registers 
    register_button(:open_party) { $actors.any? }
    register_button(:open_dex) { $game_switches[Yuki::Sw::Pokedex] }
    register_button(:open_bag) { !$bag.locked }
    register_button(:open_tcard) { true }
    register_button(:open_save) { !$game_system.save_disabled }
    register_button(:open_option) { true }

    register_button_overwrite(2) { $trainer.playing_girl ? UI::GirlBagMenuButton : nil }

  end
end

module UI
  class ClockSprite < SpriteStack
    def initialize(viewport = nil)
      super(viewport)
      create_text
    end

    def create_text
      hour = $game_variables[Yuki::Var::TJN_Hour].to_s.rjust(2, "0")
      min  = $game_variables[Yuki::Var::TJN_Min].to_s.rjust(2, "0")
      add_text(0, -6, 0, 23, hour, color: 36)
      add_text(20, -6, 0, 23, min, color: 36)
    end
  end
end

module UI
  # Button that is shown in the main menu
  class PSDKMenuButtonBase < SpriteStack
    def create_animation
      ya = Yuki::Animation

      # 🚀 Phase d'entrée : descente de 2 px
      entry_down = ya.scalar(0.10, @icon, :y=, @icon_base_y, @icon_base_y + 2)

      # 🌊 Boucle : montée de 3 puis descente de 3
      move_up   = ya.scalar(0.15, @icon, :y=, @icon_base_y + 2, @icon_base_y - 1)  # +2 -> -1 = 3 px vers le haut
      move_down = ya.scalar(0.15, @icon, :y=, @icon_base_y - 1, @icon_base_y + 2)  # redescend de 3 px

      # Chaînage
      entry_down.play_before(move_up)
      move_up.play_before(move_down)

      # Créer l'animation principale
      animation = ya.timed_loop_animation(0.30) # 0.15 + 0.15 pour la boucle
      animation.parallel_add(entry_down)

      animation.start
      return animation
    end


    def text
      case @index
      when 0 then return text_get(14, 0) # PARTY
      when 1 then return text_get(14, 1) # Dex
      when 2 then return text_get(14, 2) # BAG
      when 3 then return text_get(14, 3) # TCARD
      when 4 then return text_get(14, 4) # Save
      when 5 then return text_get(14, 5) # Options
      end
    end
  end
end



module UI
  class PSDKMenuButtonBase < SpriteStack
    attr_reader :selected_gif
    def create_icon
      # On suppose que chaque ligne du spritesheet = un bouton
      # col 0 = normal, col 1 = sélectionné
      @icon = add_sprite(3, 1, 'menu_icons', 2, 7, type: SpriteSheet)
      @icon.select(0, icon_index) # par défaut colonne 0
      @icon.set_origin(@icon.width / 2, @icon.height / 2)
      @icon.set_position(@icon.x + @icon.ox, @icon.y + @icon.oy)

      @icon_base_y = @icon.y
    end

    # Récupère la ligne correspondant au bouton
    def icon_index
      @index
    end

    # Met à jour l’apparence selon sélection
    def selected=(value)
      return if value == @selected

      if value
        # Sélectionné → colonne 1
        @icon.select(1, icon_index)
        @icon.y = @icon_base_y
        @animation = create_animation
        @selected_gif.visible = true
      else
        # Normal → colonne 0
        @icon.select(0, icon_index)
        @animation = nil
        @icon.y = @icon_base_y
        @selected_gif.visible = false
      end

      @selected = value
    end


    # Update the button animation
    def update
      @animation&.update
      @selected_gif.update
    end

    def create_selected_menu_icon_gif 
      gif = push(0, 0, nil, type: Selected_menu_icon_gif)
      gif.visible = false
      gif
    end


    def create_sprites
      create_background
      @selected_gif = create_selected_menu_icon_gif
      create_icon
      create_text
    end
  end
end


module UI
  class Selected_menu_icon_gif < Sprite
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'menu_button_selected.gif')
      @gif_reader = Yuki::GifReader.new(path)
      self.bitmap = Texture.new(@gif_reader.width, @gif_reader.height)
      @gif_reader.update(self.bitmap)
      set_origin(0,0)

      # Blink variables
      @blink_counter = 0
      @blink_phase = :off
      @blink_active = false
    end

    def start_blink(&on_end)
      @blink_counter = 0
      @blink_phase = :off
      @blink_active = true
      @on_blink_end = on_end
    end

    def update
      @gif_reader&.update(bitmap)

      return unless @blink_active

      @blink_counter += 1
      case @blink_counter
      when 1..3
        self.visible = false
      when 4..6
        self.visible = true
      when 7..9
        self.visible = false
      when 10..12
        self.visible = true
      when 13..14
        self.visible = false  # ← dernière phase, invisible
      else
        @blink_active = false
        # Assurer qu'on reste invisible à la fin
        self.visible = false
        # 🔥 Exécuter le callback si défini
        @on_blink_end&.call
        @on_blink_end = nil
      end
    end
  end
end

