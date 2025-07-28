module Battle
  class Visual
    module Transition
      # Team Rocket transition of Heartgold/Soulsilver games
      class TeamRocket < RBYTrainer
        # Y coordinate of the bar
        BAR_Y = 115
        # Text offset Y
        TEXT_Y = BAR_Y + 83
        # Text offset X
        TEXT_X = 105

        # Get the enemy trainer name
        # @return [String]
        def trainer_name
          @scene.battle_info.names[1][0]
        end

        # Return the pre_transtion sprite name
        # @return [Array<String>]
        def pre_transition_sprite_name
          return 'assets/team_rocket/hgss_bg_1', 'assets/team_rocket/hgss_bg_2', 'assets/team_rocket/hgss_strobes'
        end

        # Function that creates all the sprites
        def create_all_sprites
          super

          create_strobes_sprite
          create_screenshot_sprite
          create_background_sprite
          create_mugshot_sprite
          create_mugshot_text
          @viewport.sort_z
        end

        # Function that creates the top sprite (unused here)
        def create_top_sprite; end

        # Creates and configures the strobe sprite
        def create_strobes_sprite
          @strobes_sprite = ShaderedSprite.new(@viewport)
          @strobes_sprite.z = @screenshot_sprite.z * 3
          @strobes_sprite.load(pre_transition_sprite_name[2], :transition)

          @to_dispose << @strobes_sprite
        end

        # Creates the screenshot sprites
        def create_screenshot_sprite
          @screenshot_sprite.visible = false

          @top_screenshot_sprite = ShaderedSprite.new(@viewport)
          @top_screenshot_sprite.bitmap = @screenshot
          @top_screenshot_sprite.set_position(0, 0)
          @top_screenshot_sprite.set_rect(@top_screenshot_sprite.x, @top_screenshot_sprite.y, @top_screenshot_sprite.width,
                                          @top_screenshot_sprite.height / 2)
          @top_screenshot_sprite.z = @screenshot_sprite.z * 2

          @bottom_screenshot_sprite = ShaderedSprite.new(@viewport)
          @bottom_screenshot_sprite.bitmap = @screenshot
          @bottom_screenshot_sprite.set_position(0, @viewport.rect.height / 2)
          @bottom_screenshot_sprite.set_rect(@bottom_screenshot_sprite.x, @viewport.rect.height / 2, @bottom_screenshot_sprite.width,
                                             @bottom_screenshot_sprite.height / 2)
          @bottom_screenshot_sprite.z = @screenshot_sprite.z * 2

          @to_dispose << @screenshot_sprite << @top_screenshot_sprite << @bottom_screenshot_sprite
        end

        # Creates and configures the background sprites
        def create_background_sprite
          @first_background_sprite = ShaderedSprite.new(@viewport)
          @first_background_sprite.load(pre_transition_sprite_name[0], :transition)
          @first_background_sprite.zoom = @viewport.rect.width / @first_background_sprite.width.to_f
          @first_background_sprite.y = (@viewport.rect.height - @first_background_sprite.height * @first_background_sprite.zoom_y) / 2
          @first_background_sprite.z = @screenshot_sprite.z

          @second_background_sprite = ShaderedSprite.new(@viewport)
          @second_background_sprite.load(pre_transition_sprite_name[1], :transition)
          @second_background_sprite.zoom = @viewport.rect.width / @second_background_sprite.width.to_f
          @second_background_sprite.y = (@viewport.rect.height - @second_background_sprite.height * @second_background_sprite.zoom_y) / 2
          @second_background_sprite.z = @first_background_sprite.z + 1
          @second_background_sprite.opacity = 0

          @to_dispose << @first_background_sprite << @second_background_sprite
        end

        # Creates and configures the mugshot sprite for the trainer
        def create_mugshot_sprite
          @mugshot_sprite = ShaderedSprite.new(@viewport)
          @mugshot_sprite.load(resource_name('vs_bar/mugshot'), :battleback)
          @mugshot_sprite.set_position(@viewport.rect.width, BAR_Y)
          @mugshot_sprite.z = @screenshot_sprite.z * 3
          @mugshot_sprite.zoom = 1.4

          @to_dispose << @mugshot_sprite
        end

        # Creates and configures the text for the mugshot
        def create_mugshot_text
          @mugshot_text = Text.new(0, @viewport, -1, BAR_Y + TEXT_Y, 0, 16, trainer_name, 2, nil, 10)
          @mugshot_text.z = @screenshot_sprite.z * 3

          @to_dispose <<  @mugshot_text
        end

        # Function that creates the fade in animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_fade_in_animation
          animation = Yuki::Animation.wait(2.8)
                                     .parallel_play(create_strobes_animation)
                                     .parallel_play(create_screenshot_animation)
                                     .parallel_play(create_second_background_animation)
                                     .parallel_play(create_mugshot_animation)
                                     .parallel_play(create_pre_transition_fade_out_animation)

          return animation
        end

        # Function that creates the strobes animation
        # @return [Yuki::Animation::Dim2Animation]
        def create_strobes_animation
          start_x = @strobes_sprite.x # 0
          end_x = -@viewport.rect.width # -320
          start_y = end_y = @strobes_sprite.y

          animation = Yuki::Animation.move(0.5, @strobes_sprite, start_x, start_y, end_x, end_y)
                                     .parallel_play(create_flash_animation(0.5, 2))
          animation.play_before(Yuki::Animation.send_command_to(@strobes_sprite, :visible=, false))

          return animation
        end

        # Function that creates the screenshot animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_screenshot_animation
          animation = Yuki::Animation.wait(0.5)
          animation.play_before(create_top_screenshot_animation)
                   .parallel_play(create_bottom_screenshot_animation)

          return animation
        end

        # Function that creates the top screenshot animation
        # @return [Yuki::Animation::Dim2Animation]
        def create_top_screenshot_animation
          start_x = end_x = @top_screenshot_sprite.x
          start_y = @top_screenshot_sprite.y # 0
          end_y = -@viewport.rect.height / 2 # -120

          return Yuki::Animation.move(0.1, @top_screenshot_sprite, start_x, start_y, end_x, end_y)
        end

        # Function that creates the bottom screenshot animation
        # @return [Yuki::Animation::Dim2Animation]
        def create_bottom_screenshot_animation
          start_x = end_x = @bottom_screenshot_sprite.x
          start_y = @bottom_screenshot_sprite.y # 120
          end_y = @viewport.rect.height # 240

          return Yuki::Animation.move(0.1, @bottom_screenshot_sprite, start_x, start_y, end_x, end_y)
        end

        # Function that creates the background animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_second_background_animation
          animation = Yuki::Animation.wait(1)
          animation.play_before(Yuki::Animation.opacity_change(0.15, @second_background_sprite, 0, 255))

          return animation
        end

        # Function that creates the mugshot animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_mugshot_animation
          mugshot_sprite_real_width = @mugshot_sprite.width * @mugshot_sprite.zoom_x
          start_x = @mugshot_sprite.x # 320
          center_x = @viewport.rect.width / 2 - (mugshot_sprite_real_width / 2) # 92
          end_x = -mugshot_sprite_real_width # -134

          flash_animation = Yuki::Animation.wait(0.15)
          flash_animation.play_before(Yuki::Animation.send_command_to(@viewport, :flash, Color.new(255, 255, 255), 20))

          mugshot_entry = Yuki::Animation.move(0.15, @mugshot_sprite, start_x, BAR_Y, center_x, BAR_Y)
          mugshot_exit = Yuki::Animation.move(0.15, @mugshot_sprite, center_x, BAR_Y, end_x, BAR_Y)

          text_entry = Yuki::Animation.move_discreet(0.15, @mugshot_text, start_x, TEXT_Y, center_x + TEXT_X, TEXT_Y)
          text_exit = Yuki::Animation.move_discreet(0.15, @mugshot_text, center_x + TEXT_X, TEXT_Y, end_x, TEXT_Y)

          animation = Yuki::Animation.wait(1)
          animation.play_before(mugshot_entry)
                   .parallel_play(text_entry)
                   .parallel_play(flash_animation)
          animation.play_before(Yuki::Animation.wait(1))
          animation.play_before(mugshot_exit)
                   .parallel_play(text_exit)

          return animation
        end

        # Function that creates the pre transition fade out animation
        # @return [Yuki::Animation::TimedAnimation]
        def create_pre_transition_fade_out_animation
          transitioner = proc { |t| @viewport.shader.set_float_uniform('color', [1, 1, 1, t]) }

          animation = Yuki::Animation.wait(2.45)
          animation.play_before(Yuki::Animation.scalar(0.25, transitioner, :call, 0, 1))
          animation.play_before(Yuki::Animation.wait(0.10))

          return animation
        end
      end
    end

    TRAINER_TRANSITIONS[11] = Transition::TeamRocket
    register_transition_resource(11, :sprite)
  end
end
