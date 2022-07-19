require 'sinatra'
require 'sinatra/reloader' if development?
require "sinatra/content_for"
require "tilt/erubis"
require "logger"

require_relative "database_persistence"

configure do
  enable :sessions
  set :session_secret, 'session_secret_for_budget_app'
  disable :protection
end

configure(:development) do
  require "sinatra/reloader"
  also_reload "database_persistence.rb"
end

before do
  @storage = DatabasePersistence.new(logger)

  if session[:username]
    username = session[:username]
    @budget_id = @storage.current_budget_id(username)
    budget_overview = @storage.budget_overview(@budget_id)
  end

  if budget_overview
    @budget_name = budget_overview[:title]
    @current_funds = budget_overview[:current_funds]
    @estimated_expenses = budget_overview[:estimated_expenses]
    @total_transactions = budget_overview[:total_transactions]
    @current_balance = (@current_funds - @total_transactions).round(2)
    @budget_balance = (@current_funds - @estimated_expenses).round(2)
  end
end

# HELPERS

helpers do
  def determine_deposit_type(amount)
    amount.positive? ? "Deposit" : "Withrawl"
  end
end

# ROUTES

# BUDGET
# Load budget home page
get '/' do
  if session[:username]
    @categories = @storage.category_overview(@budget_id)
    @total_estimated_expenses = @storage.expenses_total(@budget_id)
    @all_transactions = @storage.all_transactions(@budget_id)

    erb :home
  else 
    redirect '/sign_in'
  end
end

# SIGN IN/UP
get '/sign_in' do

  erb :sign_in
end

post '/sign_in' do
  username = params[:username]
  password = params[:password]
  credentials = @storage.fetch_user_credentials(username, password)

  if credentials[:username] == username &&
     credentials[:password] == password
    session[:username] = username
  end

  redirect '/'
end

# create new user 
post '/sign_up' do
  username = params[:username]
  budget_title = params[:budget_title]
  password = params[:password]
  retyped_password = params[:retyped_password]

  if password == retyped_password
    @storage.create_new_user(username, password, budget_title)
    session[:username] = username
  end

  redirect '/'
end

post '/signout' do
  session[:username] = nil
  redirect '/'
end

# DEPOSITS
# Load deposits page
get '/deposits' do
  @deposits = @storage.all_deposits(@budget_id)

  erb :deposits
end

# Add/deduct funds from balance
post '/deposits/add' do
  deposit_amount = params[:deposit_amount].to_f

  if deposit_amount.positive?
    @storage.add_deposit(deposit_amount, @budget_id)
    session[:message] = "You've successfully added funds."
    redirect '/deposits'
  elsif deposit_amount.negative?
    @storage.add_deposit(deposit_amount, @budget_id)
    session[:message] = "You've successfully deducted funds."
    redirect '/deposits'
  else
    session[:message] = 'You must enter a positive or negative number.'
    erb :deposits
  end
end

# Delete deposit history and reset balance to 0
post '/deposits/delete_history' do
  @storage.delete_deposit_history(@budget_id)
  redirect '/deposits'
end

# CATEGORIES
# Load categories page
get '/categories' do
  @categories = @storage.category_overview(@budget_id)
  @total_estimated_expenses = @storage.expenses_total(@budget_id)
  erb :categories
end

# Load individual category page
get '/categories/:category_id' do
  category_id = params[:category_id].to_i
  @category = @storage.fetch_category(category_id)
  @category_transactions = @storage.fetch_category_transactions(category_id)

  erb :category
end

# Update individual category
post '/categories/:category_id/edit' do
  category_id = params[:category_id]
  category_name = params[:category_name]
  category_amount = params[:category_amount].to_f

  @storage.edit_category(category_id, category_name, category_amount)

  redirect '/'
end

# Add new category
post '/categories/add' do
  category_name = params[:category_name]
  category_amount = params[:category_amount].to_f

  @storage.add_category(category_name, category_amount)

  redirect '/categories'
end

# Delete a category
post '/categories/:category_id/destroy' do
  category_id = params[:category_id]
  @storage.delete_category(category_id)
  redirect '/categories'
end

# TRANSACTIONS
# Load transactions page
get '/transactions' do 
  @categories = @storage.category_overview(@budget_id)
  @all_transactions = @storage.all_transactions(@budget_id)
  
  erb :transactions
end

# Add new transaction
post '/transactions/add' do
  description = params[:description]
  amount = params[:amount].to_f
  category_id = params[:category_id].to_i
  @storage.add_transaction(category_id, description, amount)

  redirect '/'
end