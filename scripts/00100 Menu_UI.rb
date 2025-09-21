module UI
  # Button that is shown in the main menu
  class PSDKMenuButtonBase < SpriteStack
    def coordinates(index)
      # Calcul de la rangée et de la colonne
      row = index / 2   # 0,1,2
      col = index % 2   # 0,1

      # Coordonnée de départ (coin haut-gauche du bloc d’icônes)
      base_x = 60
      base_y = 40

      # Espacement entre colonnes et lignes
      col_spacing = 120  # horizontal
      row_spacing = 70  # vertical

      x = base_x + col * col_spacing
      y = base_y + row * row_spacing
      return x, y
    end
  end
end


module GamePlay
  # Main menu UI
  class Menu < BaseCleanUpdate

    # Create all the graphics
    def create_graphics
      create_viewport
      create_base
      create_background
      create_buttons
      @clock_sprite = UI::ClockSprite.new(@viewport)
      init_entering
    end

    def create_base
      @base_ui = UI::GenericBase.new(@viewport, button_texts)
    end

    def button_texts
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, ""]
    end

    # Create the background under the menu buttons
    def create_background
      # On garde le blur déjà existant
      add_disposable(@background = UI::BlurScreenshot.new(@viewport, @__last_scene))
      @background.opacity = 0

      # === TON BACKGROUND CUSTOM ===
      @menu_bg = Sprite.new(@viewport)         # créer un sprite classique
      @menu_bg.bitmap = RPG::Cache.picture('menu_bg') # ton image dans Graphics/Pictures/menu_bg.png
      @menu_bg.z = @background.z            # juste au-dessus du blur

      add_disposable(@menu_bg) # pour être nettoyé automatiquement à la fin
    end

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
      add_text(0, 0, 0, 23, hour)
      add_text(20, 0, 0, 23, min)
    end
  end
end

module UI
  # Button that is shown in the main menu
  class PSDKMenuButtonBase < SpriteStack
    def create_icon
      @icon = add_sprite(12, 0, 'menu_icons', 2, 7, type: SpriteSheet)
      @icon.select(0, icon_index)
      @icon.set_origin(@icon.width / 2, @icon.height / 2)
      @icon.set_position(@icon.x + @icon.ox, @icon.y + @icon.oy)

      # On mémorise la position Y d'origine
      @icon_base_y = @icon.y
    end

    def create_animation
      ya = Yuki::Animation
      animation = ya.timed_loop_animation(0.60)

      # Descente
      move_down = ya.scalar(0.30, @icon, :y=, @icon_base_y, @icon_base_y + 5)

      # Remontée
      move_up = ya.scalar(0.30, @icon, :y=, @icon_base_y + 5, @icon_base_y)

      # Chaîner : la montée se joue après la descente
      move_down.play_before(move_up)

      # Ajouter la séquence à l'animation principale
      animation.parallel_add(move_down)

      animation.start
      return animation
    end



        # Set the selected state
        # @param value [Boolean]
    def selected=(value)
      return if value == @selected

      if value
        # On sélectionne -> reset la position et lance l’animation
        @icon.y = @icon_base_y
        @animation = create_animation
      else
        # On désélectionne -> supprime la référence à l’animation
        @animation = nil
        # Et on remet l’icône à sa position d’origine
        @icon.y = @icon_base_y
      end

      @selected = value
    end


  end
end

