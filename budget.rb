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
  @current_balance = budget_overview[:current_funds] - budget_overview[:total_transactions]
end

get '/' do
  @categories = @storage.category_overview
  @total_estimated_expenses = @storage.total_estimated_expenses
  
  erb :home
end