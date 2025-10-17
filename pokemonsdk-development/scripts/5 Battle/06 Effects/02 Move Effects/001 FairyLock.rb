module Battle
  module Effects
    # Implement the Fairy Lock effect
    class FairyLock < EffectBase
      # Create a new effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      def initialize(logic)
        super
        self.counter = 2
      end

      # Function called when testing if creature can switch (when he couldn't passthrough)
      # @param handler [Battle::Logic::SwitchHandler]
      # @param creature [PFM::PokemonBattler]
      # @param skill [Battle::Move, nil] potential skill used to switch
      # @param reason [Symbol] the reason why the SwitchHandler is called
      # @return [:prevent, nil] if :prevent, can_switch? will return false
      def on_switch_prevention(handler, creature, skill, reason)
        return true unless triggered?
        return true if creature.type_ghost?

        return handler.prevent_change do
          handler.scene.display_message_and_wait(message(creature))
        end
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :fairy_lock
      end

      private

      # Get the "can't switch" message text
      # @param creature [PFM::PokemonBattler]
      # @return [String]
      def message(creature)
        return parse_text_with_pokemon(19, 878, creature)
      end

      # Returns whether the effect should be currently active
      # @return [Boolean]
      def triggered?
        return @counter == 1
      end
    end
  end
end
