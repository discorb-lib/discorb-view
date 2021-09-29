require "securerandom"

module Discorb::View
  #
  # Handler for the components.
  #
  class ComponentHandler < Struct.new(:object, :block)
    #
    # Redirects method calls to the object.
    #
    def method_missing(method, ...)
      object.send(method, ...)
    end

    def respond_to_missing?(method, include_private = false)
      object.respond_to?(method, include_private)
    end
  end

  #
  # Handles the rendering of the components.
  #
  class ViewHandler < Struct.new(:check, :block); end

  #
  # Base class for the view.
  # @note You should not use this class directly.
  # @abstract
  #
  module Base
    # @return [Hash{Symbol => Discorb::Component}] The components.
    attr_accessor :components
    # @return [Array<ViewHandler>] The view handlers.
    attr_accessor :views

    # @private
    def self.extended(base)
      base.prepend(Discorb::View::Base::Prepend)
      base.components = {}
      base.views = []
    end

    #
    # Adds button component to the view.
    #
    # @param [Symbol] id The id of the button.
    # @param [String] label The label of the button.
    # @param [:primary, :secondary, :success, :danger] style The style of the button.
    # @param [Discorb::Emoji, nil] emoji The emoji of the button.
    # @yield The block to execute when the button is clicked.
    # @yieldparam [Discorb::MessageComponentInteraction] interaction The interaction.
    #
    def button(id, label, style = :secondary, emoji: nil, &block)
      raise ArgumentError, "block required" unless block_given?
      button = Discorb::Button.new(label, style, emoji: emoji, custom_id: id)
      @components[id] = ComponentHandler.new(button, block)
    end

    #
    # Adds select menu component to the view.
    #
    # @param [Symbol] id The id of the button.
    # @param [String] label The label of the button.
    # @param [String, nil] placeholder The placeholder of the select menu.
    # @param [Integer, nil] min_length The minimum length of the select menu.
    # @param [Integer, nil] max_length The max length of the select menu.
    # @yield The block to execute when the menu is changed.
    # @yieldparam [Discorb::MessageComponentInteraction] interaction The interaction.
    #
    def select_menu(id, options, placeholder = nil, min_values: nil, max_values: nil, &block)
      raise ArgumentError, "block required" unless block_given?
      options.map! { |option| option.is_a?(Discorb::SelectMenu::Option) ? option : Discorb::SelectMenu::Option.new(*option) }
      menu = Discorb::SelectMenu.new(id, options, placeholder: placeholder, min_values: min_values, max_values: max_values)
      @components[id] = ComponentHandler.new(menu, block)
    end

    #
    # Add view handler to the view.
    #
    # @param [Proc, nil] check The check of the view handler.
    #   The view handler will be executed when the check returns true, or check is nil.
    # @yield The block to execute when the view handler is executed.
    # @yieldparam [Discorb::View::Base::Prepend::Result] result The result of the view.
    #
    # @note There must be one handler with no check.
    #
    def view(check = nil, &block)
      raise ArgumentError, "block required" unless block_given?
      @views.insert(0, ViewHandler.new(check, block))
    end

    #
    # Starts the view.
    #
    # @param [Discorb::Messageable] channel The channel to send the message to.
    #
    def start(channel, ...)
      client = channel.instance_variable_get(:@client)
      if @views.empty?
        raise "No views defined"
      elsif not @views.any? { |v| v.check.nil? }
        raise "No fallback view defined"
      elsif @views.filter { |v| v.check.nil? }.count > 1
        raise "Multiple fallback views defined"
      end
      view = new(client, channel, ...)
      view.start
    end

    #
    # Modules for the prepend.
    #
    module Prepend
      # @return [Discorb::MessageComponentInteraction] The interaction.
      attr_writer :interaction

      #
      # The result for rendering the view.
      #
      class Result < Struct.new(:content, :embeds, :components); end

      # @private
      def initialize(client, channel, ...)
        @client = channel.instance_variable_get(:@client)
        @channel = channel
        @message_id = nil
        @stopped = false
        @result = Result.new(nil, [], [])
        super(...)
      end

      # @private
      def start
        render
        @client.views[@message_id.to_s] = self
      end

      #
      # Stops the view.
      #
      # @param [Boolean] disable Whether to disable the components.
      # @param [Boolean] delete Whether to delete the message.
      #
      def stop!(disable: true, delete: false)
        @client.views.delete(@message_id.to_s)
        if disable
          @stopped = true
          render
        end
        @channel.delete_message!(@message_id) if delete
      end

      #
      # Renders the view.
      #
      def render
        instance_exec(@result, &actual_view.block)
        components = @result.components.map do |c|
          case c
          when Symbol
            self.class.components[c]&.object or raise ArgumentError "Unknown component ID #{c}"
          when Button
            c
          else
            raise ArgumentError "Component must be a Symbol or a Button"
          end
        end
        if @stopped
          components.each do |component|
            component.disabled = true
          end
        end
        if @interaction
          @interaction.edit(@result.content, embeds: @result.embeds, components: components).wait
        else
          msg = @channel.post(@result.content, embeds: @result.embeds, components: components).wait
          @message_id = msg.id
        end
      end

      # @private
      def actual_view
        view = self.class.views.filter { |v| v.check }.find { |v| instance_exec(@interaction, &v.check) }
        if view.nil?
          view = self.class.views.find { |v| v.check.nil? }
        end
        view
      end
    end
  end
end
