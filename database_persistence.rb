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

  def category_overview
    sql = <<~SQL
      SELECT c.id,
             c.name, 
             c.amount AS total_allocated, 
             SUM(t.amount) AS total_spent, 
             (c.amount - SUM(t.amount)) AS remaining
      FROM categories AS c
      JOIN transactions AS t
        ON c.id = t.category_id
        GROUP BY c.id, c.name, c.amount;
    SQL

    result = query(sql)

    result.map do |tuple|
      { id: tuple["id"],
        name: tuple["name"],
        total_allocated: tuple["total_allocated"],
        total_spent: tuple["total_spent"],
        remaining: tuple["remaining"]}
      end
  end

  def total_estimated_expenses
    sql = "SELECT SUM(amount) FROM categories;"

    result = query(sql)
    result.first["sum"]
  end

  private

  def query(statement, *params)
    @logger.info "statement: #{statement}"
    @logger.info "params: #{params}" 
    @db.exec_params(statement, params)
  end

end