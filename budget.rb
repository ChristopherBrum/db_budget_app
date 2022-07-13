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
  @current_balance = (@current_funds - @total_transactions).round(2)
  @budget_balance = (@current_funds - @estimated_expenses).round(2)
end

# HELPERS

helpers do
  def determine_deposit_type(amount)
    amount.positive? ? "Deposit" : "Withrawl"
  end
end

# ROUTES

# Load home page
get '/' do
  @categories = @storage.category_overview
  @total_estimated_expenses = @storage.expenses_total
  @all_transactions = @storage.all_transactions
  
  erb :home
end

get '/budget' do
  redirect '/'
end

# Delete budget
post '/budget/destroy' do
  @storage.delete_budget
  redirect '/'
end

# Load deposits page
get '/budget/deposits' do
  @deposits = @storage.all_deposits

  erb :deposits
end

# Add/deduct funds from balance
post '/budget/deposits/add' do
  deposit_amount = params[:deposit_amount].to_f

  if deposit_amount.positive?
    @storage.add_deposit(deposit_amount)
    session[:message] = "You've successfully added funds."
    redirect '/budget/deposits'
  elsif deposit_amount.negative?
    @storage.add_deposit(deposit_amount)
    session[:message] = "You've successfully deducted funds."
    redirect '/budget/deposits'
  else
    session[:message] = 'You must enter a positive or negative number.'
    erb :deposits
  end
end

# Delete deposit history and reset balance to 0
post '/budget/deposits/delete_history' do
  @storage.delete_deposit_history
  redirect '/budget/deposits'
end

# Load categories page
get '/categories' do
  @categories = @storage.category_overview
  @total_estimated_expenses = @storage.expenses_total
  erb :categories
end

# Add new category
post '/categories/add' do
  category_name = params[:category_name]
  category_amount = params[:category_amount]

  @storage.add_category(category_name, category_amount)

  redirect '/categories'
end

# Delete a category
post '/categories/:category_id/destroy' do
  category_id = params[:category_id]
  @storage.delete_category(category_id)
  redirect '/categories'
end