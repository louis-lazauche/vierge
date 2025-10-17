module PFM
  class Pokemon
    # Module adding the Shedinja special evolution case to PSDK.
    # You can remove this file from the script list to effectively remove this case from your project
    module ShedinjaSpecialEvolutionCase
      def evolve(...)
        super(...)
        return unless db_symbol == :ninjask && !PFM.game_state.full? && $bag.contain_item?(:poke_ball)

        attributes = {
          nature: nature_db_symbol,
          stats: [iv_hp, iv_atk, iv_dfe, iv_spd, iv_ats, iv_dfs],
          bonus: [ev_hp, ev_atk, ev_dfe, ev_spd, ev_ats, ev_dfs],
          trainer_name: trainer_name, trainer_id: trainer_id,
          captured_in: captured_in, captured_at: captured_at, captured_level: captured_level,
          egg_in: egg_in, egg_at: egg_at,
          moves: skills_set.map(&:id)
        }
        shedinja = Pokemon.new(:shedinja, level, shiny?, !shiny?, 0, attributes)
        $actors << shedinja
        $bag.remove_item(:poke_ball, 1)
        $pokedex.mark_seen(:shedinja, forced: true)
        $pokedex.mark_captured(:shedinja)
      end
    end

    prepend ShedinjaSpecialEvolutionCase
  end
end
