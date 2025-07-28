module Battle
  # Safari battles scene
  class Safari < Scene
    # The current Safari Pokémon shown in the battle scene
    # @return [PokemonBattler]
    attr_accessor :safari_pokemon

    # Stage modifying a Pokemon's catch rate
    # @return [Integer]
    attr_accessor :catch_rate_modifier

    # Stage modifying a Pokemon's flee chance
    # @return [Integer]
    attr_accessor :flee_rate_modifier

    # Initialisation for Safari battle scene
    def initialize(battle_info)
      super
      @safari_pokemon = logic.battler(1, @player_actions.size)
      player_pkmn = logic.battler(0, @player_actions.size)
      @pkmn_base_flee_rate = ((255 - @safari_pokemon.rareness + @safari_pokemon.base_spd) / 2).clamp(1, 255)
      @catch_rate_modifier = 0
      @flee_rate_modifier = 0

      @safari_pokemon.effects.add(Effects::AbilitySuppressed.new(@logic, @safari_pokemon))
      player_pkmn.effects.add(Effects::AbilitySuppressed.new(@logic, player_pkmn))

      logic.item_change_handler.change_item(:none, false, @safari_pokemon, @safari_pokemon, self)
      logic.item_change_handler.change_item(:none, false, player_pkmn, player_pkmn, self)
    end

    # Method that ask for the player choice (it calls @visual.show_player_choice)
    def player_action_choice
      # If the method was called and the player cannot make another choice it's a bug so we end the battle
      return @next_update = :battle_end unless can_player_make_another_action_choice?

      choice, _forced_action = @visual.show_player_choice(@player_actions.size)
      log_debug("Player action choice : #{choice}")
      case choice
      when :safari_ball
        try_safari_catch
      when :bait
        throw_bait
        @next_update = :pokemon_turn
      when :mud
        throw_mud
        @next_update = :pokemon_turn
      when :flee
        flee
      else
        # The visual interface detected an anomaly, we go to the end of the battle
        @next_update = :battle_end
      end
    ensure
      @skip_frame = true
    end

    # Throw a bait at the Pokémon, increasing its catch rate modifier by 1. Also has a 90% chance of increasing its flee rate modifier by 1
    # In case the flee rate modifier is not increased, a special message is shown
    def throw_bait
      @visual.show_bait_mud_animation(@safari_pokemon, :bait)
      @message_window.wait_input = true
      display_message_and_wait(throw_bait_message)

      @catch_rate_modifier += 1
      @catch_rate_modifier.clamp(-6, 6)
      log_debug("New catch rate modifier: #{@catch_rate_modifier}")

      if @logic.generic_rng.rand(0..99) < 90
        @flee_rate_modifier += 1
        @flee_rate_modifier.clamp(-6, 6)
        log_debug("New flee rate modifier: #{@flee_rate_modifier}")
      else
        @message_window.wait_input = true
        display_message_and_wait(ten_percent_bait_message)
      end
    end

    # Throw mud at the Pokémon, decreasing its flee rate modifier by 1. Also has a 90% chance of decreasing its catch rate modifier by 1
    # In case the catch rate modifier is not decreased, a special message is shown
    def throw_mud
      @visual.show_bait_mud_animation(@safari_pokemon, :mud)
      @message_window.wait_input = true
      display_message_and_wait(throw_mud_message)

      @flee_rate_modifier -= 1
      @flee_rate_modifier.clamp(-6, 6)
      log_debug("New flee rate modifier: #{@flee_rate_modifier}")

      if @logic.generic_rng.rand(0..99) < 90
        @catch_rate_modifier -= 1
        @catch_rate_modifier.clamp(-6, 6)
        log_debug("New catch rate modifier: #{@catch_rate_modifier}")
      else
        @message_window.wait_input = true
        display_message_and_wait(ten_percent_mud_message)
      end
    end

    # Try to send a Safari Ball to catch the Pokémon
    # If the player has no Safari Balls left, the battle ends
    def try_safari_catch
      if $bag.contain_item?(:safari_ball)
        item_wrapper = PFM::ItemDescriptor.actions(:safari_ball)
        PFM.game_state.bag.remove_item(:safari_ball, 1)
        caught(item_wrapper)
      else
        @message_window.wait_input = true
        display_message_and_wait(parse_text(71, 18))
        display_message_and_wait(pokemon_flee_message)
        @logic.battle_result = 1
        @next_update = :battle_end
      end
    end

    # Return the stage modifier (multiplier)
    # @param stage [Integer] the value of the stage
    # @return [Float] the multiplier
    def modifier_stage(stage)
      if stage >= 0
        return (2 + stage) / 2.0
      else
        return 2.0 / (2 - stage)
      end
    end

    # Method to catch a Pokémon
    # @param item_wrapper [PFM::ItemDescriptor::Wrapper]
    def caught(item_wrapper)
      computed_catch_rate = (@safari_pokemon.rareness * modifier_stage(@catch_rate_modifier)).clamp(1, 255)
      @safari_pokemon.rareness = computed_catch_rate
      log_data("Computed catch rate: #{computed_catch_rate}")
      if (caught = logic.catch_handler.try_to_catch_pokemon(logic.alive_battlers(1)[0], logic.alive_battlers(0)[0], item_wrapper.item))
        logic.battle_info.caught_pokemon = logic.alive_battlers(1)[0]
        give_pokemon_procedure(logic.battle_info.caught_pokemon, item_wrapper.item)
      end
      @next_update = caught ? :battle_end : :pokemon_turn
    end

    # Method that makes the player flee the battle, no verification needed in Safari battles
    def flee
      @message_window.width = @visual.viewport.rect.width if @visual.viewport
      @message_window.wait_input = true
      display_message_and_wait(parse_text(18, 75))
      @logic.battle_result = 1
      @next_update = :battle_end
    end

    # Engage the turn of the wild Pokemon, check if it flees or if the battle proceeds
    def pokemon_turn
      computed_flee_rate = (@pkmn_base_flee_rate * modifier_stage(@flee_rate_modifier)).clamp(1, 255)
      log_data("Computed flee rate: #{computed_flee_rate}")
      @message_window.wait_input = true
      if @logic.generic_rng.rand(0..254) <= computed_flee_rate
        display_message(pokemon_flee_message)
        @logic.battle_result = 1
        @next_update = :battle_end
      else
        display_message(battle_continues_message)
        @next_update = :player_action_choice
      end
    end

    # Get the message shown when throwing a bait
    def throw_bait_message
      return parse_text_with_pokemon(71, 0, @safari_pokemon)
    end

    # Get the message shown when throwing mud
    def throw_mud_message
      return parse_text_with_pokemon(71, 3, @safari_pokemon)
    end

    # Get the message shown when throwing a bait and the flee rate is not increased
    def ten_percent_bait_message
      return parse_text_with_pokemon(71, 6, @safari_pokemon)
    end

    # Get the message shown when throwing mud and the catch rate is not decreased
    def ten_percent_mud_message
      return parse_text_with_pokemon(71, 9, @safari_pokemon)
    end

    # Get the message shown when the Safari Pokemon flees
    def pokemon_flee_message
      parse_text_with_pokemon(71, 12, @safari_pokemon)
    end

    # Get the message shown when the Safari Pokemon does not flee and the battle continues
    def battle_continues_message
      parse_text_with_pokemon(71, 15, @safari_pokemon)
    end
  end
end
