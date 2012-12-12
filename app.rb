require 'sinatra'
require 'sinatra/partial'
require 'sinatra/reloader' if development?

require 'redis'

configure do
    redisUri = ENV["REDISTOGO_URL"] || 'redis://localhost:6379'
    uri = URI.parse(redisUri) 
    $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

get '/' do
    redirect '/fish'
end

get %r{/([\w]+)} do
    word = params[:captures].first

    puns = []
    $redis.lrange("puns:#{word}", 0, $redis.llen("puns:#{word}") ).each do |pun|
        puns.push( JSON.parse( pun ) )
    end

    erb :main, :locals => {
        :all_words => $redis.smembers("all_words"),
        :word => $redis.get(word),
        :puns => puns
    }
end

def is_valid( word, pun )
    # first create a list of the display words so we can check against that for errors
    puns = []
    $redis.lrange("puns:#{word}", 0, $redis.llen("puns:#{word}") ).each do |pun|
        puns.push( JSON.parse( pun )["word"] )
    end

    #word is a duplicate
    if puns.include? pun.gsub(/\s+/, "").downcase()
        print "failed 1, swagger jockin'"
        return false
    end

    # word is too long
    if pun.length == 0 or pun.length > 60
        print "failed 2, too much swag."
        return false
    end

    # no "word"
    if pun.gsub(/\s+/, "").downcase().index( word ) == nil
        print "failed 3, no 'swag'"
        return false
    end

    # wo rd
    if pun.gsub(/\s+/, "").downcase() == word
        print "failed 4, sw ag"
        return false
    end

    # we're good to go
    return true
end

post '/add' do
    word = params[:word]
    pun = params[:pun]

    if pun && word
        if is_valid( word, pun )
            entry = pun.gsub(/\s+/, "").downcase()
            $redis.lpush("puns:#{word}", {:word=>entry,:display=>pun}.to_json)

            return { :result => "success", :pun => pun }.to_json
        else
            return { :result => "fail", :msg => "Duplicate entry? Too many characters? Not a pun?! :)" }.to_json
        end
    else
        return { :result => "fail", :msg => "invalid request" }.to_json
    end
end