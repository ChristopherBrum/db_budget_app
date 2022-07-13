require 'sinatra'
require 'sinatra/reloader' if development?
require "sinatra/content_for"
require "tilt/erubis"
require "logger"

require_relative "database_persistence"

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)

  budget_overview = @storage.budget_overview
  @budget_name = budget_overview[:name]
  @current_funds = budget_overview[:current_funds]
  @estimated_expenses = budget_overview[:estimated_expenses]
  @total_transactions = budget_overview[:total_transactions]
  @balance = (budget_overview[:current_funds] - budget_overview[:total_transactions]).round(2)
end

# HELPERS

helpers do
  def determine_deposit_type(amount)
    amount.positive? ? "Deposit" : "Withrawl"
  end
end

# ROUTES

get '/' do
  @categories = @storage.category_overview
  @total_estimated_expenses = @storage.expenses_total
  @all_transactions = @storage.all_transactions
  
  erb :home
end

get '/budget' do
  redirect '/'
end

get '/budget/add_funds' do
  @deposits = @storage.all_deposits

  erb :add_funds
end

post '/budget/add_funds' do
  deposit_amount = params[:deposit_amount].to_f

  if deposit_amount.positive?
    @storage.add_funds(deposit_amount)
    session[:message] = "You've successfully added funds."
    redirect '/'
  elsif deposit_amount.negative?
    @storage.add_funds(deposit_amount)
    session[:message] = "You've successfully deducted funds."
    redirect '/'
  else
    session[:message] = 'You must enter a positive or negative number.'
    erb :add_funds
  end
end
