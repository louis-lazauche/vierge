module UI
  # Class that shows a static background gif (ignores Pokémon data)
  class BackgroundGifSprite < Sprite
    # Create the gif background sprite
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'my_background.gif')
      @gif_reader = Yuki::GifReader.new(path)
      self.bitmap = Texture.new(@gif_reader.width, @gif_reader.height)
      @gif_reader.update(self.bitmap)
      set_origin(0,0)
    end

    # Update the gif animation
    def update
      @gif_reader&.update(bitmap)
    end
  end
end

module UI
  # Class that shows a static background gif (ignores Pokémon data)
  class BackgroundGifSprite2 < Sprite
    # Create the gif background sprite
    # @param viewport [Viewport]
    def initialize(viewport)
      super(viewport)
      path = File.join('graphics', 'interface', 'summary_stat.gif')
      @gif_reader = Yuki::GifReader.new(path)
      self.bitmap = Texture.new(@gif_reader.width, @gif_reader.height)
      @gif_reader.update(self.bitmap)
      set_origin(0,0)
    end

    # Update the gif animation
    def update
      @gif_reader&.update(bitmap)
    end
  end
end


module UI
  # UI part displaying the generic information of the Pokemon in the Summary
  class Summary_Top < SpriteStack
    # @return [SymText]
    def create_name_text
      add_text(220, 4, 10, 16, :given_name, type: SymText, sizeid: 5, color: 19)
    end

    # @return [GenderSprite]
    def create_gender
      @gender_sprite = push(300, 8, nil, type: GenderSprite)
    end

        # @return [Sprite]
    def create_ball
      push(210, 12, nil, ox: 16, oy: 16)
    end
  end
end



class PFM::Pokemon
  # Retourne l'index de caractéristique (0..29)
  def characteristic_id
    ivs = [iv_hp, iv_atk, iv_dfe, iv_spd, iv_ats, iv_dfs]
    max_iv = ivs.max
    # Trouver la première stat avec cet IV max
    stat_index = ivs.index(max_iv)
    # Formule officielle
    return stat_index * 5 + (max_iv % 5)
  end

  # Retourne le texte d'humeur (caractéristique)
  def characteristic
    base_index = 49 # début des textes d'humeur dans studio
    return Studio::Text.get(28, base_index + characteristic_id)
  end
end



#-----------------------------------------------------------------------------
#                              BARRE EXP
#-----------------------------------------------------------------------------


module UI
  class Summary_Memo < SpriteStack
    def create_exp_bar
      bar = Bar.new(@viewport, 101, 195, RPG::Cache.interface('bar_exp'), 80, 3, 0, 0, 1)
      # Define the data source of the EXP Bar
      bar.data_source = :exp_rate
      return bar
    end
  end
end


#-----------------------------------------------------------------------------
#                              BARRE HP
#-----------------------------------------------------------------------------
module UI
  class Summary_Stat < SpriteStack
    def create_hp_bg
      add_sprite(85, 36, RPG::Cache.interface('menu_pokemon_hp'), rect: Rect.new(0, 0, 66, 7))
    end

    def create_hp_bar
      bar = Bar.new(@viewport, 102, 38, RPG::Cache.interface('team/HPBars'), 48, 3, 0, 0, 3)
      # Define the data source of the HP Bar
      bar.data_source = :hp_rate
      return bar
    end
  end
end

class Spriteset_Map
  def create_zoom(start_value, end_value, duration)
    @zoom_animation = Yuki::Animation.scalar(duration, @viewport1, :zoom=, start_value, end_value)
    @zoom_animation.start
  end

  def reset_zoom
    @zoom_animation = nil
    return unless @viewport1 && !@viewport1.disposed?
    @viewport1.zoom = 1
  end

  Hooks.register(self, :reload, 'Reset Zoom') { reset_zoom }
  Hooks.register(self, :dispose, 'Reset Zoom') { reset_zoom }

  def update_zoom_animation
    return unless @zoom_animation
    @zoom_animation.update
    @zoom_animation = nil if @zoom_animation.done?
  end

  Hooks.register(self, :update, 'Zoom Animation') { update_zoom_animation }
end
