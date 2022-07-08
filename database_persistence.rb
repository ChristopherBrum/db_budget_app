require "pg"

class DatabasePersistence
  def initialize(logger)
    @logger = logger
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "budgets")
          end
  end

  def budget_overview
    sql = <<~SQL
      SELECT b.name, 
             b.balance, 
             SUM(c.amount) AS estimated_expenses, 
             SUM(t.amount) AS total_transactions
        FROM budgets AS b
        INNER JOIN categories AS c ON b.id = c.budget_id
        INNER JOIN transactions AS t ON c.id = t.category_id
        GROUP BY b.name, b.balance;
    SQL

    result = query(sql)
    tuple = result.first

    { name: tuple["name"], 
      current_funds: tuple["balance"].to_f, 
      estimated_expenses: tuple["estimated_expenses"].to_f,
      total_transactions: tuple["total_transactions"].to_f }
  end

  private

  def query(statement, *params)
    @logger.info "statement: #{statement}"
    @logger.info "params: #{params}" 
    @db.exec_params(statement, params)
  end

end