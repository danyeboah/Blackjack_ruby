require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret' 
BLACKJACK_NUMBER = 21
DEALER_MIN = 17

helpers do
  def card_total (cards_set)
    values = cards_set.map {|card| card[1]}
    total = 0
    values.each do |x|
      if x == "ace"
        total += 11
      elsif x.to_i == 0
        total += 10
      else
        total += x.to_i
      end
    end

   no_of_aces = values.count {|card_value| card_value == "ace"}

    # reduce value of ace to 1 if total > BLACKJACK_NUMBER
    while ((total > BLACKJACK_NUMBER) && (no_of_aces > 0))
      total -= 10
      no_of_aces -= 1
    end

    return total
  end

  def card_image(card)
    card_name = card[0] + "_" + card[1] + ".jpg"
    return "<img src='/images/cards/#{card_name}' class='image_card' alt = #{card} />" 
  end

  def player_wins(message)
    @winning = message
    session[:money_remaining] += session[:bet_amount]
    @show_hit_stay_buttons = false
    @play_again = true
    @show_computer_button = false
  end

  def player_loses(message)
    @losing = message
    session[:money_remaining] -= session[:bet_amount]
    @show_hit_stay_buttons = false
    @play_again = true
    @show_computer_button = false
  end
end

before do
  @show_hit_stay_buttons = true
  @dealer_turn = false
  @play_again = false
end

get '/' do 
  session[:money_remaining] = 500
	if session[:username]
		redirect '/bet'
	else
		redirect '/user_name_form'
	end
end

# form to enter name
get '/user_name_form' do
	erb :user_name_form
end

# form to enter bet
get '/bet' do
  if session[:money_remaining] <= 0
    @error = "Sorry, take your broke ass home"
    halt erb :game_over
  end
  erb :bet
end

# process bet post
post '/bet/bet_post' do
  bet_amount = params[:bet_amount].to_i
  if (bet_amount > 0 && bet_amount <= session[:money_remaining])
    session[:bet_amount] = bet_amount
    redirect '/game'
  else
    @error = "Duh...You cannot bet more or less than you have"
    halt erb :bet
  end  
end

post '/user_name_action' do
  if params[:user_name].empty?
    @error = "Please type in a name"
    halt erb :user_name_form
  end
	session[:user_name] = params[:user_name]
	redirect '/bet'
end

get '/game' do
	cards = []
  (2..10).each {|card| cards[card - 2] = card.to_s}   

  cards.push('jack','queen','king','ace')
 
  # array of suits
  suits = ["hearts", "diamonds", "clubs", "spades"]   

  # create first deck and shuffle
  deck = suits.product(cards).shuffle!

  session[:deck] = deck
  session[:user_cards] = []
  session[:computer_cards] = []

  session[:user_cards] << session[:deck].pop
  session[:computer_cards] << session[:deck].pop
  session[:user_cards] << session[:deck].pop
  session[:computer_cards] << session[:deck].pop

  @show_computer_button = false
 
	erb :game
end

post '/game/player/hit' do
  session[:user_cards] << session[:deck].pop
  user_total = card_total(session[:user_cards])
  if user_total> BLACKJACK_NUMBER
    player_loses("Sorry #{session[:user_name]}...You Busted! at #{user_total}") 
  elsif user_total == BLACKJACK_NUMBER
    player_wins("BLACKJACK! You Won $#{session[:bet_amount]}!!!")
  end
  erb :game
end

post '/game/player/stay' do
  @show_hit_stay_buttons = false
  @dealer_turn = true
  @show_computer_button = true

  if card_total(session[:user_cards]) == BLACKJACK_NUMBER
    player_wins("BLACKJACK! You won $#{session[:bet_amount]}!!!") 
  end

  erb :game
end

post '/game/computer/computer_move' do
  computer_total = card_total(session[:computer_cards])
  @dealer_turn = true
  @show_hit_stay_buttons = true

  if card_total(session[:computer_cards]) == BLACKJACK_NUMBER
     player_loses("Dealer has BLACKJACK!!!...You lost")
     halt erb :game
  end
  
  if ((computer_total < DEALER_MIN) || (computer_total < card_total(session[:user_cards]))) 
    @computer_hits = true
    session[:computer_cards] << session[:deck].pop
    @show_computer_button = true

  else
    @computer_stays = true
    redirect '/game/decide_winner'
  end

  computer_total = card_total(session[:computer_cards])
  if computer_total > BLACKJACK_NUMBER
    player_wins("You won #{session[:user_name]}! Dealer busted! at #{computer_total} You won $#{session[:bet_amount]}")
  end

  erb :game
end

get '/game/decide_winner' do
  @dealer_turn = true
  @show_hit_stay_buttons = false
  @computer_stays = true
  
  computer_total = card_total(session[:computer_cards])
  user_total = card_total(session[:user_cards])

  if computer_total > user_total
    player_loses("Sorry #{session[:user_name]} you lost")
  elsif user_total > computer_total
    player_wins("Congratulations #{session[:user_name]}! You Won $#{session[:bet_amount]}!!!")
  else
    @winning = "It's a tie"
    @play_again = true
  end

  erb :game
end  

get '/game/game_over' do
  erb :game_over
end


  

