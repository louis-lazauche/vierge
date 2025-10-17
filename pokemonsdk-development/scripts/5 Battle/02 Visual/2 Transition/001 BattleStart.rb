module Battle
  # Module holding all the message function used by the battle engine
  module Message
    include PFM::Text
    # @type [Battle::Logic::BattleInfo] battle infos (to retrieve some stuff)
    @battle_info = nil
    # @type [Battle::Logic] the battle logic (to retrieve some stuff)
    @logic = nil

    module_function

    # Setup the message system
    # @param logic [Battle::Logic] the current battle logic
    def setup(logic)
      @battle_info = logic.battle_info
      @logic = logic
      @text = PFM::Text
    end

    # A Wild Pokemon appeared
    # @return [String]
    def wild_battle_appearance
      sentence_index = @battle_info.wild_battle_reason.to_i % 7
      name, name2, name3 = @logic.all_battlers.reject(&:from_party?).map(&:name)

      hash = {
        PKNAME[0] => name,
        PKNAME[1] => name2,
        PKNAME[2] => name3
      }

      if name2.nil?
        @text.parse(18, 1 + sentence_index, hash)
      elsif name3.nil?
        @text.parse(73, 2, hash)
      else
        @text.parse(73, 3, hash)
      end
    end

    # Trainer issuing a challenge
    # @return [String]
    def trainer_issuing_a_challenge
      @text.reset_variables
      @text.set_plural(@battle_info.names[1].size > 1)

      case @battle_info.names[1].size
      when 1
        trainer_issuing_a_challenge_single
      when 2
        trainer_issuing_a_challenge_double_trainer
      when 3
        trainer_issuing_a_challenge_triple_trainer
      end
    end

    # Player sending out its Pokemon
    # @return [String]
    def player_sending_pokemon_start
      @text.reset_variables
      @text.set_plural(false)
      @battle_info.names[0].size > 1 ? player_sending_pokemon_start_multi : player_sending_pokemon_start_single
    end

    # Trainer sending out their Pokemon
    # @return [String]
    def trainer_sending_pokemon_start
      @text.reset_variables
      @text.set_plural(@battle_info.trainer_is_couple || @battle_info.trainer_is_triplet)
      text = []
      @battle_info.names[1].each_with_index do |name, index|
        if (class_name = @battle_info.classes[1][index])
          text << trainer_sending_pokemon_start_class(name, class_name, index)
        else
          text << trainer_sending_pokemon_start_no_class(name, index)
        end
      end
      text.join("\n")
    end

    # Trainer issuing a challenge with 2 trainers
    # @return [String]
    def trainer_issuing_a_challenge_double_trainer
      text_id = @battle_info.classes[1].empty? ? 11 : 10
      if @battle_info.classes[1].empty?
        hash = {
          TRNAME[0] => @battle_info.names[1][0],
          TRNAME[1] => @battle_info.names[1][1]
        }
      else
        hash = {
          TRNAME[1] => @battle_info.names[1][0],
          TRNAME[3] => @battle_info.names[1][1],
          '[VAR 010E(0000)]' => @battle_info.classes[1][0],
          '[VAR 010E(0002)]' => @battle_info.classes[1][1] || @battle_info.classes[1][0]
        }
        hash['[VAR 019E(0000)]'] = "#{hash['[VAR 010E(0000)]']} #{hash[TRNAME[1]]}"
        hash['[VAR 019E(0002)]'] = "#{hash['[VAR 010E(0002)]']} #{hash[TRNAME[3]]}"
      end
      @text.parse(18, text_id, hash)
    end

    # Trainer issuing a challenge with 3 trainers
    # @return [String]
    def trainer_issuing_a_challenge_triple_trainer
      text_id = @battle_info.classes[1].empty? ? 1 : 0
      if @battle_info.classes[1].empty?
        hash = {
          TRNAME[1] => @battle_info.names[1][0],
          TRNAME[2] => @battle_info.names[1][1],
          TRNAME[3] => @battle_info.names[1][2]
        }
      else
        hash = {
          TRNAME[1] => @battle_info.names[1][0],
          TRNAME[2] => @battle_info.names[1][1],
          TRNAME[3] => @battle_info.names[1][2],
          '[VAR 010E(0000)]' => @battle_info.classes[1][0],
          '[VAR 010E(0001)]' => @battle_info.classes[1][1] || @battle_info.classes[1][0],
          '[VAR 010E(0002)]' => @battle_info.classes[1][2] || @battle_info.classes[1][0]
        }
        hash['[VAR 019E(0000)]'] = "#{hash['[VAR 010E(0000)]']} #{hash[TRNAME[1]]}"
        hash['[VAR 019E(0001)]'] = "#{hash['[VAR 010E(0001)]']} #{hash[TRNAME[2]]}"
        hash['[VAR 019E(0002)]'] = "#{hash['[VAR 010E(0002)]']} #{hash[TRNAME[3]]}"
      end
      @text.parse(73, text_id, hash)
    end

    # Trainer issuing a challenge with one trainer
    # @return [String]
    def trainer_issuing_a_challenge_single
      text_id = @battle_info.classes[1].empty? ? 9 : 8
      if @battle_info.classes[1].empty?
        hash = { TRNAME[0] => @battle_info.names[1][0] }
      else
        hash = {
          TRNAME[1] => @battle_info.names[1][0],
          '[VAR 010E(0000)]' => @battle_info.classes[1][0]
        }
        hash['[VAR 019E(0000)]'] = "#{hash['[VAR 010E(0000)]']} #{hash[TRNAME[1]]}"
      end
      @text.parse(18, text_id, hash)
    end

    # When there's a friend trainer and we launch the Pokemon
    # @return [String]
    def player_sending_pokemon_start_multi
      text = [@text.parse(18, 18, PKNICK[1] => @logic.battler(0, 0).name, TRNAME[0] => @battle_info.names[0][0])]
      if @battle_info.classes[0][1]
        @text.set_pknick(@logic.battler(0, 1), 2)
        hash = {
          TRNAME[1] => @battle_info.names[0][1],
          '[VAR 010E(0000)]' => @battle_info.classes[0][1]
        }
        hash['[VAR 019E(0000)]'] = "#{hash['[VAR 010E(0000)]']} #{hash[TRNAME[1]]}"
        text << @text.parse(18, 15, hash)
      else
        @text.set_pknick(@logic.battler(0, 1), 1)
        text << @text.parse(18, 18, TRNAME[0] => @battle_info.names[0][0])
      end
      text.join("\n")
    end

    # When were' alone and we launch the Pokemon
    # @return [String]
    def player_sending_pokemon_start_single
      (count = @logic.battler_count(0)).times do |i|
        @text.set_pknick(@logic.battler(0, i), i)
      end
      return @text.parse(18, 14) if count == 3
      return @text.parse(18, 13) if count == 2

      return @text.parse(18, 12)
    ensure
      @text.reset_variables
    end

    # When the trainer has a class and it sends out its Pokemon
    # @param name [String] name of the trainer
    # @param class_name [String] class of the trainer
    # @param index [String] index of the trainer in the name array
    # @return [String]
    def trainer_sending_pokemon_start_class(name, class_name, index)
      hash = {
        TRNAME[1] => name,
        '[VAR 010E(0000)]' => class_name
      }
      hash['[VAR 019E(0000)]'] = "#{class_name} #{name}"
      # Get the pokemon
      arr = Array.new(@battle_info.vs_type) { |i| @logic.battler(1, i) }
      arr.select! { |pokemon| pokemon&.party_id == index }
      arr.each_with_index { |pokemon, i| @text.set_pknick(pokemon, i + 2) }
      return @text.parse(18, 15 + arr.size - 1, hash)
    ensure
      @text.reset_variables
    end

    # When the trainer has no class and it sends out its Pokemon
    # @param name [String] name of the trainer
    # @param index [String] index of the trainer in the name array
    # @return [String]
    def trainer_sending_pokemon_start_no_class(name, index)
      # Get the pokemon
      arr = Array.new(@battle_info.vs_type) { |i| @logic.battler(1, i) }
      arr.select! { |pokemon| pokemon&.party_id == index }
      arr.each_with_index { |pokemon, i| @text.set_pknick(pokemon, i + 2) }
      return @text.parse(18, 18 + arr.size - 1, TRNAME[0] => name)
    ensure
      @text.reset_variables
    end
  end
end
