module PFM
  class Wild_Battle
    # Hash describing which method to seek to change the Pokemon chances depending on the player's leading Pokemon's talent
    CHANGE_POKEMON_CHANCE = {
      keen_eye: :rate_intimidate_keen_eye,
      intimidate: :rate_intimidate_keen_eye,
      cute_charm: :rate_cute_charm,
      magnet_pull: :rate_magnet_pull,
      static: :rate_static,
      lightning_rod: :rate_static,
      flash_fire: :rate_flash_fire,
      storm_drain: :rate_storm_drain,
      harvest: :rate_harvest
    }

    # Hash describing which method to seek to change the Pokemon data depending on the player's leading Pokemon's talent
    DATA_ALTERING_ABILITIES = {
      synchronize: :copy_nature_synchronize,
      compound_eyes: :change_item_compound_eyes,
      super_luck: :change_item_compound_eyes
    }

    private

    # Alter the creatures' data from sources
    # @param creatures [Array<PFM::Pokemon>]
    # @return [Array<PFM::Pokemon>]
    def alter_creatures(creatures)
      return [] unless creatures && !creatures.empty?

      main_creature = $actors[0]
      ability = creature_ability

      return creatures.map do |creature|
        send(DATA_ALTERING_ABILITIES[ability], creature, main_creature) if respond_to?(DATA_ALTERING_ABILITIES[ability] || :__undef__, true)
        creature
      end
    end

    # Configure the creature array for later selection
    # @param creatures [Array<PFM::Pokemon>]
    # @return [Array<Array(PFM::Pokemon, Float),nil>] all creatures with their rate to get selected
    def configure_creature(creatures)
      return [] unless creatures && !creatures.empty?

      main_creature = $actors[0]
      ability = creature_ability

      return creatures.map do |creature|
        rate = 1
        rate = send(CHANGE_POKEMON_CHANCE[ability], creature, main_creature) if respond_to?(CHANGE_POKEMON_CHANCE[ability] || :__undef__, true)
        # Cleanse tag & repel
        if creature.level < main_creature.level
          rate *= 0.33 if main_creature.item_db_symbol == :cleanse_tag
          rate = 0 if repel_active? && !fishing_battle?
        end
        next [creature, rate]
      end
    end

    # Get rate for Intimidate/Keen Eye cases
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_intimidate_keen_eye(creature, main_creature)
      return (creature.level + 5) < main_creature.level ? 0.5 : 1
    end

    # Get rate for Cute Charm case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_cute_charm(creature, main_creature)
      return (creature.gender * main_creature.gender) == 2 ? 1.5 : 1
    end

    # Get rate for Magnet Pull case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_magnet_pull(creature, main_creature)
      return creature.type_steel? ? 1.5 : 1
    end

    # Get rate for Statik case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_static(creature, main_creature)
      return creature.type_electric? ? 1.5 : 1
    end

    # Get rate for Storm Drain case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_storm_drain(creature, main_creature)
      return creature.type_water? ? 1.5 : 1
    end

    # Get rate for Flash Fire case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_flash_fire(creature, main_creature)
      return creature.type_fire? ? 1.5 : 1
    end

    # Get rate for Harvest case
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @return [Float] new rate or 1
    def rate_harvest(creature, main_creature)
      return creature.type_grass? ? 1.5 : 1
    end

    # Changes the nature of the wild pokemon to the nature of the Synchronize pokemon (50% chance)
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    def copy_nature_synchronize(creature, main_creature)
      creature.nature = main_creature.nature_id if Random::WILD_BATTLE.rand(100) < 50
    end

    # Enhance the item rate if the leader has Compound Eyes or Super Luck
    # @param creature [PFM::Pokemon] creature to select
    # @param main_creature [PFM::Pokemon] pokemon that caused the rate verification
    # @note This method is used for both Compound Eyes and Super Luck starting from gen 8
    # @note In base games, rates go from 5% and 50% to 20% and 60%
    def change_item_compound_eyes(creature, main_creature)
      return unless creature.item_holding == 0

      items = data_creature_form(creature.db_symbol, creature.form).item_held
      log_debug("Compound Eyes proc on #{creature.name}")
      rng = rand(100)
      item_holding = items.find do |item|
        chance = item.chance <= 10 ? item.chance * 4 : item.chance * 1.2
        log_debug("New item odd: #{data_item(item.db_symbol).name} => #{chance}")
        next true if rng < chance

        rng -= chance
        next false
      end
      creature.item_holding = item_holding ? data_item(item_holding.db_symbol).id : 0
    end

    # Select the creatures that will be in the battle
    # @param group [Studio::Group] the descriptor of the Wild group
    # @param creature_to_select [Array<Array(PFM::Pokemon, Float)>] list of Pokemon to select with their rates
    # @return [Array<PFM::Pokemon,nil>]
    def select_creature(group, creature_to_select)
      return [] unless group && !group.encounters.empty?
      return [] if creature_to_select.empty?

      main_creature = $actors[0]

      real_rareness = creature_to_select.map.with_index do |(creature, rate), index|
        encounter = group.encounters[index % group.encounters.size]
        next [creature, 0] if repel_active? && !fishing_battle? && creature.level < main_creature.level

        next [creature, rate * encounter.encounter_rate]
      end

      # This reducer prevents to select the exact same Creature twice
      reduced_rareness = real_rareness.reduce([]) { |acc, curr| acc << (curr.last + (acc.last || 0)) }
      max_rand = reduced_rareness.last
      return [] if max_rand.to_i.zero?

      return encounter_amount(group).times.reduce([]) do |acc, _|
        nb = Random::WILD_BATTLE.rand(max_rand.to_i)
        index = reduced_rareness.find_index { |i| i > nb } || real_rareness.size - 1
        creature = real_rareness[index].first
        redo if acc.include?(creature)
        acc << creature
      end
    end

    # Configure the wild battle
    # @param enemy_arr [Array<PFM::Pokemon>]
    # @param battle_id [Integer] ID of the events to load for battle scenario
    # @return [Battle::Logic::BattleInfo]
    def configure_battle(enemy_arr, battle_id)
      return if (!enemy_arr.is_a? Array) || !enemy_arr || enemy_arr&.empty?

      has_roaming = enemy_arr.any? { |pokemon| roaming?(pokemon) }
      info = Battle::Logic::BattleInfo.new
      info.add_party(0, *info.player_basic_info)
      add_ally_trainer(info, $game_variables[Yuki::Var::Allied_Trainer_ID])
      add_ally_trainer(info, $game_variables[Yuki::Var::Second_Allied_Trainer_ID])
      info.add_party(1, enemy_arr, nil, nil, nil, nil, nil, has_roaming ? -1 : 0)
      info.battle_id = battle_id
      info.fishing = !@fish_battle.nil?
      info.vs_type = enemy_arr.size > 3 ? 3 : enemy_arr.size
      return info
    end

    # Configurate the ally trainer for the Wild Battle if an ally is specified
    # @param bi [Battle::Logic::BattleInfo]
    # @param allied_trainer_id [Integer]
    def add_ally_trainer(bi, allied_trainer_id)
      return unless allied_trainer_id.positive?

      ally = data_trainer(allied_trainer_id)
      bag = PFM::Bag.new
      ally.bag_entries.each { |bag_entry| bag.add_item(bag_entry[:dbSymbol], bag_entry[:amount]) }
      party = ally.party.map(&:to_creature)
      bi.add_party(0, party, ally.name, ally.class_name, ally.resources.sprite, bag, ally.base_money, ally.ai)
    end

    # Check if repel is active
    # @return [Boolean]
    def repel_active?
      return PFM.game_state.repel_count > 0
    end

    # Check if the battle is a fishing battle
    # @return [Boolean]
    def fishing_battle?
      return FISHING_TOOLS.include?(current_selected_group.tool)
    end
  end
end
