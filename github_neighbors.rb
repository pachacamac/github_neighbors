#!/usr/bin/env ruby
require 'rest_client'
require 'base64'
require 'json'

user = '' #insert your GitHub username
pass = '' #insert your GitHub password

AUTH = "Basic "+Base64.encode64("#{user}:#{pass}").strip
RestClient.proxy = ENV['http_proxy']

def get(path)
  JSON.parse(RestClient.get("https://api.github.com/#{path}", :Authorization => AUTH))
end

def fill_graph(user, depth=1, graph={}, cache={})
  return graph if cache[user]
  cache[user] = true
  puts user
  File.open("#{user}.png",'w'){|f|f.write RestClient.get(get("users/#{user}")['avatar_url'])} unless File.exist? "#{user}.png"
  graph[user] = {:image=>"#{user}.png",:style=>"filled"}
  graph[user][:fillcolor] = (depth == 1 ? 'red' : 'green')
  get("users/#{user}/followers").map{|e|e['login']}.each do |follower|
    graph[[follower,user]]||={}
    graph = fill_graph(follower, depth-1, graph, cache) if depth > 0
  end
  get("users/#{user}/following").map{|e|e['login']}.each do |following|
    graph[[user,following]]||={}
    graph = fill_graph(following, depth-1, graph, cache) if depth > 0
  end
  graph
end


graph = fill_graph(user)

File.open('github.dot','w') do |f|
  f.puts 'digraph G {'
  graph.keys.select{|e|e.is_a? String}.each do |e|
    f.puts "\"#{e}\" [#{graph[e].map{|k,v| "#{k}=\"#{v}\""}.join(', ')}];"
  end
  graph.keys.select{|e|e.is_a? Array}.each do |e|
    f.puts "\"#{e[0]}\" -> \"#{e[1]}\";"
  end
  f.puts '}'
end
system 'circo -Tpng -oout.png github.dot'

