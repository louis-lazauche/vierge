module GamePlay
  # Load game scene
  class Load < BaseCleanUpdate

    ACTIONS = %i[action_a action_a action_a action_b action_b action_a action_a action_a action_a action_b]

    def create_graphics
      super
      create_base_ui
      create_static_background   
      create_signs
    end

    # Update the load scene graphics
    def update_graphics
      # @base_ui&.update_background_animation
      @signs.each(&:update)
    end

    def button_texts
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, ""]
    end

    def create_static_background
      @static_bg = Sprite.new(@viewport)
      @static_bg.load('load/static_bg', :interface) # ton image fixe
      @static_bg.z = 0 # pour être derrière la barre des boutons
    end
  end
end


module UI
  # UI element showing the save information
  class SaveSign < SpriteStack

    module SaveHelper
      # Formate la vraie date de sauvegarde
      def self.real_save_time_text(game_state)
        timestamp = game_state.game_variables[Yuki::Var::Last_Real_Save_Timestamp]
        if timestamp && timestamp > 0
          Time.at(timestamp).strftime("%d/%m    %H:%M")
        else
          "-"
        end
      end
    end

    # méthode utilitaire : cache tous les textes
    def hide_all_texts
      @save_text.visible = false
      @save_label_text.visible = false
      @save_date_text.visible = false
      @new_game_text.visible = false
      @new_corrupted_text.visible = false
    end


    def show_new_game
      hide_all_texts
      @swap_sprites.each { |sp| sp.visible = false }
      @background.load('load/box_new', :interface)
      @background.set_origin(7, -45)
      @cursor.load('load/cursor_main', :interface)

      @new_game_text.visible = true
    end

    def show_corrupted
      hide_all_texts
      @swap_sprites.each { |sp| sp.visible = false } # cacher les infos du joueur
      @background.load('load/box_corrupted', :interface)
      @background.set_origin(7, -45)
      @cursor.load('load/cursor_main', :interface)

      @new_corrupted_text.visible = true               # texte Corrupted visible
      @new_corrupted_text.text = corrupted_message
    end

    def create_save_text
      # Texte pour les slots normaux (Save 1, Save 2…)
      @save_text = add_text(0, 1, 226, 16, '', 1, sizeid: 5)

      # Texte pour Nouvelle partie (⚠️ pas ajouté à @swap_sprites)
      @new_game_text = add_text(14, 50, 200, 16, ext_text(9000, 0), 1, color: 10, sizeid: 5)
      @new_game_text.visible = false

      # Texte pour partie corrompue (⚠️ pas ajouté à @swap_sprites)
      @new_corrupted_text = add_text(14, 50, 200, 16, "", 1, color: 2, sizeid: 5)
      @new_corrupted_text.visible = false

      # Label "Dernière sauvegarde :"
      @save_label_text = add_text(-40, -48, 150, 16, "Dernière sauvegarde :", 1, sizeid: 5, color: 9)

      # Texte pour la date de la save
      @save_date_text = add_text(110, -48, 100, 16, "", 1, sizeid: 5, color: 9)

      # On ajoute SEULEMENT les textes normaux aux swap_sprites
      @swap_sprites << @save_text << @save_label_text << @save_date_text
    end


    # Show the save data
    # @param value [PFM::GameState]
    def show_data(value)
      hide_all_texts
      @swap_sprites.each { |sp| sp.visible = true }
      @background.load('load/box_main', :interface)
      @background.set_origin(22, 0)
      @cursor.load('load/cursor_main', :interface)

      @save_text.visible = true
      @save_label_text.visible = true
      @save_date_text.visible = true
      @save_text.text = format(save_index_message, @save_index)
      @save_date_text.text = SaveHelper.real_save_time_text(value)

      show_save_data(value)

      # ➕ On récupère l'heure/minute ingame et on les affiche
      hour = value.game_variables[Yuki::Var::TJN_Hour]
      min  = value.game_variables[Yuki::Var::TJN_Min]
      if hour && min
        @ingame_time_text.text = sprintf("%02d:%02d", hour, min)
      else
        @ingame_time_text.text = ""
      end
    end

    def create_cursor
      @cursor = add_sprite(-40, -4, NO_INITIAL_IMAGE, 1, 2, type: SpriteSheet)
    end

    # Animate the cursor when moving
    def animate_cursor
      @cursor.visible = true
      @animation = Yuki::Animation::TimedLoopAnimation.new(0.5)
      @animation.play_before(Yuki::Animation.wait(0.5))
      parallel = Yuki::Animation.send_command_to(@cursor, :sy=, 0)
      parallel.play_before(Yuki::Animation.wait(0.25))
      parallel.play_before(Yuki::Animation.send_command_to(@cursor, :sy=, 1))
      @animation.parallel_add(parallel)
      @animation.start
    end

    def spacing_x
      310
    end

    def create_save_info_text
      @location_text = add_text(65, 23, 0, 16, '', color: 9, sizeid: 5)
      @swap_sprites << @location_text

      @badge_text = add_text(65, 57, 0, 16, text_get(25, 1), color: 9, sizeid: 5)
      @swap_sprites << @badge_text
      @badge_value = add_text(129, 57, 0, 16, '', 2, color: 9, sizeid: 5)
      @swap_sprites << @badge_value

      @pokedex_text = add_text(148, 57, 0, 16, text_get(25, 3), color: 9, sizeid: 5)
      @swap_sprites << @pokedex_text
      @pokedex_value = add_text(218, 57, 0, 16, '', 2, color: 9, sizeid: 5)
      @swap_sprites << @pokedex_value
      @time_text = add_text(65, 77, 0, 16, text_get(25, 5), color: 9, sizeid: 5)
      @swap_sprites << @time_text
      # Temps de jeu total (play_time déjà géré)
      @time_value = add_text(191, 77, 0, 16, '', 2, color: 9, sizeid: 5)
      @swap_sprites << @time_value

      # ➕ Nouveau texte : Heure/minute ingame
      @ingame_time_text = add_text(200, 23, 0, 16, '', color: 9, sizeid: 5)
      @swap_sprites << @ingame_time_text
    end

    def create_pokemon_sprites
      @pokemon_sprites = Array.new(6) { |i| add_sprite(5 + i * 43, 115, NO_INITIAL_IMAGE, type: PokemonIconSprite) }
      @pokemon_sprites.each { |sprite| sprite.zoom = 1.4 }
      @swap_sprites.concat(@pokemon_sprites)
    end

    def create_player_sprite
      @player_sprite = add_sprite(13, 78, NO_INITIAL_IMAGE, 4, 4, type: SpriteSheet)
      @player_sprite.zoom = 1.4
      @swap_sprites << @player_sprite
    end

    def create_player_name
      @player_name = add_text(15, 79, 0, 16, '', 1, color: player_name_color, sizeid: 5)
      @swap_sprites << @player_name
    end

  end
end

module Yuki
  module Var
    # Timestamp de la vraie sauvegarde (heure système)
    Last_Real_Save_Timestamp = 100
  end
end

module GamePlay
  # Save game scene
  class Save < Load
    # Save the game (method allowing hooks on the save)
    def save_game
      # Avant d'appeler Save.save
      $game_variables[Yuki::Var::Last_Real_Save_Timestamp] = Time.now.to_i
      Save.save
    end

    def button_texts
      [nil, nil, nil, nil, nil, nil, nil, nil, "", ""]
    end
  end
end
