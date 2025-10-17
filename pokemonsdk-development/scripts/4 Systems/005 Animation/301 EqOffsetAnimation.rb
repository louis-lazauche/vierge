module Yuki
  module Animation
    # Class applying equation to sprite property using defined equation.
    #
    # Equations are named and all their parameter is given by a hash.
    # You can apply equations on several properties of the sprite.
    #
    # Here's the name of the equations and their parameters:
    # - `:linear` => `a * t + b`
    # - `:quadratic` => `a * t² + b * t + c`
    # - `:cosine` => `a * cos(2pi * f * t + phi) + b`
    # - `:variable_cosine` => `(a * cos(2pi * f2 * t + phi2) + b) * cos(2pi * f * t + phi) + c`
    #
    # Note: t ∈ [0, 1]
    #
    # Equations may be expressed this way: `[[:property1, :equation_name, { **params }], [:property2, :equation_name, { **params }]]``
    class EqAnimation < TimedAnimation
      include Math
      SPRITE_PROPERTY_TO_SETTER = { x: :x=, y: :y=, z: :z=, ox: :ox=, oy: :oy=, angle: :angle=, opacity: :opacity= }
      TWO_PI = 2 * PI

      # Create a new EqAnimation animation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param equations [Array<Array[property, eq, params]>] list of equations to apply
      # @param distortion [#call, Symbol] callable taking one paramater (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distord time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, equations, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @equations_param = equations
      end

      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @on = resolve(@on_param)
        @equations = resolve(@equations_param)
        @single = @equations.size === 1 ? @equations[0] : nil
      end

      private

      # Update the scalar animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        if @single
          assign_property(@single[0], send(@single[1], @single[2], time_factor))
        else
          @equations.each do |eq|
            assign_property(eq[0], send(eq[1], eq[2], time_factor))
          end
        end
      end

      # Assign the property of a sprite to the value of an equation
      # @param property [Symbol]
      # @param value [Float]
      def assign_property(property, value)
        @on.send(SPRITE_PROPERTY_TO_SETTER[property], value)
      end

      module Offset
        private

        # Assign the property of a sprite to the value of an equation
        # @param property [Symbol]
        # @param value [Float]
        def assign_property(property, value)
          super(property, value + @on.send(property))
        end
      end

      # Define the linear equation
      # @param params [Hash]
      # @param t [Float]
      def linear(params, t)
        return params[:a] * t + params[:b]
      end

      # Define the quadratic equation
      # @param params [Hash]
      # @param t [Float]
      def quadratic(params, t)
        return params[:a] * (t ** 2) + params[:b] * t + params[:c]
      end

      # Define the quadratic equation
      # @param params [Hash]
      # @param t [Float]
      def cosine(params, t)
        return params[:a] * cos(TWO_PI * params[:f] * t + params[:phi]) + params[:b]
      end

      # Define the quadratic equation
      # @param params [Hash]
      # @param t [Float]
      def variable_cosine(params, t)
        amplitude = (params[:a] * cos(TWO_PI * params[:f2] * t + params[:phi2]) + params[:b])
        return amplitude * cos(TWO_PI * params[:f] * t + params[:phi]) + params[:c]
      end
    end

    # Class offset-ing another sprite using a defined equation.
    #
    # All equations will be added to the value of the property
    # For more information, check EqAnimation.
    class EqOffsetAnimation < EqAnimation
      prepend Offset
    end

    module_function

    # Create a new EqAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param equations [Array<Array[property, eq, params]>] list of equations to apply
    # @param distortion [#call, Symbol] callable taking one paramater (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distord time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @example ya.eq(ttp, sym, [[:angle, :cosine, { a: 360, f: 1 / 5.0, phi: pi2, b: 0 }]]))
    def eq(time_to_process, on, equations, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return EqAnimation.new(time_to_process, on, equations, distortion: distortion, time_source: time_source)
    end

    # Create a new EqOffsetAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param equations [Array<Array[property, eq, params]>] list of equations to apply
    # @param distortion [#call, Symbol] callable taking one paramater (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distord time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    def eq_offset(time_to_process, on, equations, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return EqOffsetAnimation.new(time_to_process, on, equations, distortion: distortion, time_source: time_source)
    end
  end
end
