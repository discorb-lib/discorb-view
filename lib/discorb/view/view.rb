require "securerandom"

module Discorb::View
  Handler = Struct.new(:object, :block)
  ViewHandler = Struct.new(:check, :block)

  module Base
    attr_accessor :handlers
    def self.extended(base)
      base.prepend(Discorb::View::Base::Prepend)
      @handlers = {}
    end

    def button(label, type = :secondary, emoji: nil, &block)
      button = Discorb::Button.new(label, type, emoji: emoji)
      @handlers[SecureRandom.hex(16)] = Handler.new(button, block)
    end

    def view(check = nil, &block)
      @views << ViewHandler.new(check, &block)
    end

    def start(client, ...)
      if @views.empty?
        raise "No views defined"
      elsif not @views.any? { |v| v.check.nil? }
        raise "No fallback view defined"
      end
      view = new(client, ...)
      @client.views[view.identifier] = view
    end

    module Prepend
      attr_reader :identifier

      def initialize(client, ...)
        @identifier = SecureRandom.hex(16)
        @client = client
        super
      end
    end
  end
end
