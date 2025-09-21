# Patch pour zoomer le splash à x1.25
class Scene_Title
  # Monkey patch du chargement du splash pour appliquer le zoom
  alias_method :orig_psdk_splash_initialize, :psdk_splash_initialize
  def psdk_splash_initialize
    @background = Sprite.new(@viewport)
    @background.opacity = 0
    @background.load('nintendo', :title)
    @current_state = :title_animation
    create_splash_animation    
    if @background && @background.bitmap
      @background.zoom_x = 1.25
      @background.zoom_y = 1.25
    end
  end

  alias_method :orig_next_splash_initialize, :next_splash_initialize
  def next_splash_initialize
    orig_next_splash_initialize
    if @background && @background.bitmap
      @background.zoom_x = 1.25
      @background.zoom_y = 1.25
    end
  end
end
# Sprite clignotant "appuyez sur entrée" en bas du title screen
class Scene_Title
  def create_press_enter_sprite
    screen_width = Graphics.width
    screen_height = Graphics.height
    @press_enter_viewport = Viewport.new(0, 205, screen_width, 60)
    @press_enter_viewport.z = 400
    @press_enter_sprite = Sprite.new(@press_enter_viewport)
    @press_enter_sprite.z = 401
    @press_enter_sprite.load('press_enter', :title) # Place ton image dans Graphics/Titles
    @press_enter_sprite.x = (screen_width - @press_enter_sprite.width) / 2
    @press_enter_sprite.y = 0
    @press_enter_blink_timer = 0
    @press_enter_blink_interval = 60 # intervalle plus lent (1s si 60 FPS)
  end
  def create_title_sprite_on_top
    screen_width = Graphics.width
    screen_height = Graphics.height
    # On affiche le titre dans un viewport comme press_enter, mais en haut
    @title_top_viewport = Viewport.new(0, 0, screen_width, screen_height)
    @title_top_viewport.z = 400 # même z que press_enter, au-dessus des Plane
    @title_top_sprite = Sprite.new(@title_top_viewport)
    @title_top_sprite.z = 401
    @title_top_sprite.load('title', :title) # Graphics/Titles/title.png
    @title_top_sprite.x = (screen_width - @title_top_sprite.width) / 2
    @title_top_sprite.y = 0
  end

  def update_press_enter_sprite
    return unless @press_enter_sprite
    @press_enter_blink_timer = (@press_enter_blink_timer + 1) % (@press_enter_blink_interval * 2)
    @press_enter_sprite.visible = @press_enter_blink_timer < @press_enter_blink_interval
  end
end

# Patch Scene_Title pour ignorer la gestion de la souris sur le title screen
class Scene_Title
  def update_mouse(moved)
    # Ne rien faire, évite l'erreur liée à play_bg/credit_bg nil
  end
end
# Patch Scene_Title pour forcer l'action 'jouer' sur Entrée
class Scene_Title
  # Monkey patch de update_inputs pour ignorer les contrôles et lancer le menu de load game sur Entrée
  def update_inputs
    return false unless !@splash_animation || @splash_animation.done?

    if @current_state != :title_animation
      send(@current_state)
      return false
    elsif @bgm_duration && Audio.bgm_position >= @bgm_duration
      @running = false
      $scene = Scene_Title.new
      return false
    end

    if Input.trigger?(:A) || Mouse.trigger?(:LEFT)
      action_a # Lance le menu de load game
      return false
    end

    return true
  end
end
# Patch UI::TitleControls pour masquer les boutons et textes, désactiver le curseur, et forcer la logique sur 'jouer'
module UI
  class TitleControls
    # Monkey patch pour masquer tous les éléments visuels
    def create_sprites
      # Ne crée aucun bouton ni texte
    end

    # Désactive l'animation du curseur
    def create_animation
      @animation = Yuki::Animation.wait(9999) # Animation inactive
      @animation.start
    end

    # Force l'index sur 'jouer' et ne montre rien
    def index=(index)
      @index = 0
    end

    # Empêche toute update visuelle
    def update
      # rien
    end
  end
end

# Monkey patch pour scroll horizontal parfait d'un PNG sur l'écran titre
# Utilise Plane pour un scroll fluide et sans coupure

class Scene_Title
  # Crée le Plane pour le scroll PNG
  def create_title_scrolling_plane
    screen_width = Graphics.width
    # Plane gauche (droite vers gauche)
    @title_scroll_viewport = Viewport.new(0, 0, screen_width / 2, 100)
    @title_scroll_viewport.z = 300
    @title_scroll_plane = Plane.new(@title_scroll_viewport)
    @title_scroll_plane.z = 301
    @title_scroll_plane.bitmap = RPG::Cache.title('title_anim_2') # PNG à placer dans Graphics/Titles
    @title_scroll_plane.ox = 0
    @title_scroll_plane.oy = 0
    @title_scroll_speed = 0.5 # pixels par frame (ralenti)

    # Plane droite (gauche vers droite)
    @title_scroll_viewport_right = Viewport.new(screen_width / 2, 0, screen_width / 2, 100)
    @title_scroll_viewport_right.z = 300
    @title_scroll_plane_right = Plane.new(@title_scroll_viewport_right)
    @title_scroll_plane_right.z = 301
    @title_scroll_plane_right.bitmap = RPG::Cache.title('title_anim')
    @title_scroll_plane_right.ox = 0
    @title_scroll_plane_right.oy = 0
    @title_scroll_speed_right = 0.5
  end

  # Met à jour le scroll du Plane
  def update_title_scrolling_plane
    # Scroll gauche (droite vers gauche)
    if @title_scroll_plane
      @title_scroll_plane.ox = (@title_scroll_plane.ox + @title_scroll_speed) % @title_scroll_plane.bitmap.width
    end
    # Scroll droite (gauche vers droite)
    if @title_scroll_plane_right
      @title_scroll_plane_right.ox = (@title_scroll_plane_right.ox - @title_scroll_speed_right) % @title_scroll_plane_right.bitmap.width
    end
  end
end

module TitleUIPlanePatch
  def create_title_graphics
    create_title_background
    create_title_controls
    create_title_scrolling_plane
    create_title_sprite_on_top
    create_press_enter_sprite
  end

  def update_graphics
    super
    update_title_scrolling_plane
    update_press_enter_sprite
  end
end

Scene_Title.prepend(TitleUIPlanePatch)
