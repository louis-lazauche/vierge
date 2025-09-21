module GamePlay
  class TCard < BaseCleanUpdate::FrameBalanced
    def initialize(*args)
      super
      @state = 0
      @current_animation = nil
      @pending_state = nil
    end

    def update_graphics
      @base_ui.update_background_animation
      if @current_animation
        @current_animation.update
        if @current_animation.done?
          if @pending_state
            # Mettre à jour l'état
            real_change_state(@pending_state)
            @pending_state = nil
          end

          # Supprimer l'overlay noir s'il existe
          if @black_overlay
            @black_overlay.dispose
            @black_overlay = nil
          end

          @current_animation = nil
        end
      end
    end


    # Lance une rotation simulée avec zoom_x
    def start_flip_animation(target, new_state, duration = 0.8)
      @pending_state = new_state
      # Étape 1 : réduire zoom_x 1 -> 0
      @current_animation = Yuki::Animation::ScalarAnimation.new(duration / 2.0, target, :zoom_x=, target.zoom_x, 0)
      @current_animation.start
      # On “enchaînera” la 2e moitié dans real_change_state
    end

    # Crée un overlay noir dans le viewport, prêt à être animé
    def create_black_overlay
      overlay = Sprite.new(@viewport)
      # On crée un petit Bitmap 1x1 noir et on le stretch pour couvrir l'écran
      overlay.set_bitmap(nil) # Bitmap vide
      overlay.bitmap = Bitmap.new(1, 1) # 1x1
      overlay.bitmap.fill_rect(0, 0, 1, 1, Color.new(0, 0, 0))
      overlay.zoom_x = @viewport.rect.width.to_f
      overlay.zoom_y = @viewport.rect.height.to_f
      overlay.x = 0
      overlay.y = @viewport.rect.height # commence en bas
      overlay
    end

    # Overlay noir pour le slide down, recouvre entièrement l'écran depuis le haut
    def create_black_overlay_for_slide_down
      overlay = Sprite.new(@viewport)
      overlay.bitmap = Bitmap.new(1, 1)
      overlay.bitmap.fill_rect(0, 0, 1, 1, Color.new(0, 0, 0))

      overlay.zoom_x = @viewport.rect.width.to_f
      overlay.zoom_y = @viewport.rect.height.to_f

      overlay.x = 0
      overlay.y = -@viewport.rect.height  # commence juste au-dessus de l'écran

      overlay
    end

    # Anime l'overlay du bas vers le haut
    def start_slide_up_black(duration = 0.2, target_state = 2)
      black_overlay = create_black_overlay
      # On anime la position Y
      @current_animation = Yuki::Animation::ScalarAnimation.new(duration, black_overlay, :y=, black_overlay.y, 0)
      @current_animation.start

      # On change l'état une fois l'animation terminée
      @pending_state = target_state
    end

    def start_slide_down_black(duration = 0.4, target_state = 0)
      @black_overlay = create_black_overlay_for_slide_down

      # anime le rectangle vers le bas pour recouvrir complètement l'écran
      @current_animation = Yuki::Animation::ScalarAnimation.new(
        duration,
        @black_overlay,
        :y=,
        @black_overlay.y,         # départ : -height
        0                         # arrivée : coin supérieur aligné en haut
      )
      @current_animation.start

      # changer l'état derrière le noir
      @pending_state = target_state
    end






    def change_state(state)
      if @state == 0 && state == 2
        # main_ui -> badges_ui : overlay qui monte
        start_slide_up_black(0.2, 2)
      elsif @state == 2 && state == 0
        start_slide_down_black(0.2, 0)
      elsif (@state == 0 && state == 1) || (@state == 1 && state == 0)
        # flip entre main et alt UI
        start_flip_animation(@sub_background || Sprite.new(@viewport), state)
      else
        # fade standard pour les autres transitions
        real_change_state(state, duration: 0.8, with_fade: true)
      end
    end





    def real_change_state(state, duration: 0.8, with_fade: false)
      @state = state
      case @state
      when 0 then show_main_ui
      when 1 then show_alt_ui
      when 2 then show_badges_ui
      end

      if @sub_background
        if with_fade
          @sub_background.opacity = 0
          @current_animation = Yuki::Animation.opacity_change(duration, @sub_background, 0, 255)
        else
          @current_animation = Yuki::Animation::ScalarAnimation.new(duration / 2.0, @sub_background, :zoom_x=, 0, 1.25)
        end
        @current_animation.start
      end
    end

    # --- Ajout : gestion des inputs ---
    def update_inputs
      if Input.trigger?(:B)
        return @running = false
      elsif Input.trigger?(:A)
        $game_system.se_play($data_system.decision_se)
        change_state(@state == 0 ? 1 : 0) unless @state == 2
      elsif Input.trigger?(:X)
        $game_system.se_play($data_system.decision_se) 
        change_state(@state == 2 ? 0 : 2) unless @state == 1
      end
      true
    end


    # --- Ajout : affichage page principale ---
    def show_main_ui
      dispose_alt_ui
      dispose_badges_ui
      create_sub_background
      create_texts
      create_trainer_sprite
    end

    # --- Ajout : affichage page alternative ---
    def show_badges_ui
      dispose_main_ui
      dispose_alt_ui
      create_sub_background_badges
      @alt_texts = UI::SpriteStack.new(@viewport)
      @alt_texts.add_text(160, 100, 0, 16, "Page 2 : Infos additionnelles", 1, color: 9)
      @alt_texts.add_text(160, 130, 0, 16, "À remplir selon tes besoins", 1, color: 9)
    end

    # --- Ajout : affichage page secrète ---
    def show_alt_ui
      dispose_main_ui
      dispose_badges_ui
      create_sub_background_alt
      @secret_texts = UI::SpriteStack.new(@viewport)
      @secret_texts.add_text(160, 120, 0, 16, "État secret débloqué !", 1, color: 10)
      @secret_texts.add_text(160, 150, 0, 16, "Exclusif à la main_ui", 1, color: 10)
    end

    # --- Ajout : nettoyage ---
    def dispose_main_ui
      @texts&.dispose
      @texts = nil
      @sub_background&.dispose
      @sub_background = nil
      @trainer_sprite&.dispose
      @trainer_sprite = nil
    end

    def dispose_alt_ui
      @alt_texts&.dispose
      @alt_texts = nil
      @sub_background&.dispose
      @sub_background = nil
    end

    def dispose_badges_ui
      @secret_texts&.dispose
      @secret_texts = nil
      @sub_background&.dispose
      @sub_background = nil
    end

    def center_sprite(sprite, cx, cy)
      return unless sprite&.bitmap
      sprite.ox = sprite.bitmap.width / 2
      sprite.oy = sprite.bitmap.height / 2
      sprite.x = cx
      sprite.y = cy
    end

    def create_sub_background
      @sub_background = Sprite.new(@viewport).set_bitmap('tcard/background', :interface)
      @sub_background.zoom_x = 1.25
      @sub_background.zoom_y = 1.25
      center_sprite(@sub_background, 160, 105) # centré écran
    end

    def create_sub_background_badges
      @sub_background = Sprite.new(@viewport).set_bitmap('tcard/background_badges', :interface)
      @sub_background.zoom_x = 1.25
      @sub_background.zoom_y = 1.25
      center_sprite(@sub_background, 160, 105) # centré écran
    end

    def create_sub_background_alt
      @sub_background = Sprite.new(@viewport).set_bitmap('tcard/background_2', :interface)
      @sub_background.zoom_x = 1.25
      @sub_background.zoom_y = 1.25
      center_sprite(@sub_background, 160, 105) # centré écran
    end

    # Create the texts
    def create_texts
      @texts = UI::SpriteStack.new(@viewport)
      # Show the start time
      create_start_time
      create_money
      create_name
      create_do
      create_badge
      create_play_time
      create_pokedex_text

      pokedex = PFM.game_state.pokedex
      seen_count  = pokedex.instance_variable_get(:@creature_seen)
      owned_count = pokedex.instance_variable_get(:@creature_owned)
      @pokedex_value.text = "#{seen_count}"
    end

    def create_pokedex_text
      @pokedex_text  = @texts.add_text(148, 57, 0, 16, text_get(25, 3), color: 9, sizeid: 5)
      @pokedex_value = @texts.add_text(208, 57, 0, 16, '', 2, color: 9, sizeid: 5)
    end
  end
end










    # def initialize(viewport, visual_index)
    #   super(viewport, *coordinates(visual_index))
    #   create_sprites
    #   @save_index = 0
    #   @visual_index = visual_index
    # end

    # # Show the save data
    # # @param value [PFM::GameState]
    # def show_save_data(value)
    #   @player_sprite.load(value.game_player.character_name, :character)
    #   @player_sprite.set_origin(@player_sprite.width / 2, @player_sprite.height)
    #   $game_actors = value.game_actors
    #   $game_variables = value.game_variables
    #   @location_text.text = PFM::Text.parse_string_for_messages(value.env.current_zone_name)
    #   @player_name.text = value.trainer.name
    #   @badge_value&.text = value.trainer.badge_counter.to_s
    #   @pokedex_value&.text = value.pokedex.creature_seen.to_s
    #   @time_value&.text = value.trainer.play_time_text
    #   @pokemon_sprites.each_with_index do |sprite, index|
    #     sprite.data = value.actors[index]
    #   end
    # ensure
    #   $game_actors = PFM.game_state&.game_actors
    #   $game_variables = PFM.game_state&.game_variables
    # end