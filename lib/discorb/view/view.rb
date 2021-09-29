require "securerandom"

module Discorb::View
  Handler = Struct.new(:object, :block)
  ViewHandler = Struct.new(:check, :block)

  module Base
    attr_accessor :components
    attr_accessor :views

    def self.extended(base)
      base.prepend(Discorb::View::Base::Prepend)
      base.components = {}
      base.views = []
    end

    def button(id, label, type = :secondary, emoji: nil, &block)
      raise ArgumentError, "block required" unless block_given?
      button = Discorb::Button.new(label, type, emoji: emoji, custom_id: id)
      @components[id] = Handler.new(button, block)
    end

    def select_menu(id, options, placeholder = nil, min_values: nil, max_values: nil, &block)
      raise ArgumentError, "block required" unless block_given?
      options.map! { |option| option.is_a?(Discorb::SelectMenu::Option) ? option : Discorb::SelectMenu::Option.new(*option) }
      menu = Discorb::SelectMenu.new(id, options, placeholder: placeholder, min_values: min_values, max_values: max_values)
      @components[id] = Handler.new(menu, block)
    end

    def view(check = nil, &block)
      raise ArgumentError, "block required" unless block_given?
      @views.insert(0, ViewHandler.new(check, block))
    end

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

    module Prepend
      attr_writer :interaction
      Result = Struct.new(:content, :embeds, :components)

      def initialize(client, channel, ...)
        @client = channel.instance_variable_get(:@client)
        @channel = channel
        @message_id = nil
        @stopped = false
        @result = Result.new(nil, [], [])
        super(...)
      end

      def start
        render
        @client.views[@message_id.to_s] = self
      end

      def stop!(disable: true, delete: false)
        @client.views.delete(@message_id.to_s)
        if disable
          @stopped = true
          render
        end
        @channel.delete_message!(@message_id) if delete
      end

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

      def actual_view
        view = self.class.views.filter { |v| v.check }.find { |v| instance_exec(@client, &v.check) }
        if view.nil?
          view = self.class.views.find { |v| v.check.nil? }
        end
        view
      end
    end
  end
end
