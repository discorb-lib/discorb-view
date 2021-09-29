require "discorb"
require "discorb/view"

client = Discorb::Client.new

client.extend Discorb::View::Extension

class MyMenu
  extend Discorb::View::Base

  @@texts = ["A", "B"]

  def initialize
    @page = 0
  end

  button :left, "<", :primary do |interaction|
    @page -= 1
  end

  button :right, ">", :primary do |interaction|
    @page += 1
  end

  button :quit, "Quit", :danger do |interaction|
    stop!
  end

  view ->(interaction) { !((0...@@texts.length).include?(@page)) } do |result|
    result.content = "Out of range: Page #{@page + 1}"
  end

  view do |result|
    result.content = @@texts[@page % @@texts.length]
    result.embeds = []
    result.components = [:left, :right, :quit]
  end
end

client.once :standby do
  puts "Ready!"
end

client.on :message do |message|
  next unless message.content == "menu"

  MyMenu.start(message.channel)
end

client.run ENV["DISCORD_BOT_TOKEN"]
