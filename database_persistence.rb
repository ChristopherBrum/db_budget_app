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

  def current_budget_id(username)
    sql = <<~SQL
      SELECT b.id FROM budgets AS b
      JOIN users AS u
        ON u.id = b.user_id
        WHERE u.username LIKE $1;
    SQL

    result = query(sql, username)
    result.first["id"]
  end

  def budget_overview(budget_id)
    sql = <<~SQL
      SELECT b.title, 
             b.balance, 
             SUM(c.amount) AS estimated_expenses, 
             SUM(t.amount) AS total_transactions
        FROM budgets AS b
        JOIN categories AS c ON b.id = c.budget_id
        LEFT JOIN transactions AS t ON c.id = t.category_id
        GROUP BY b.title, b.balance, b.id
        HAVING b.id = $1;
    SQL

    result = query(sql, budget_id)
    tuple = result.first

    if tuple
      { title: tuple["title"], 
        current_funds: tuple["balance"].to_f, 
        estimated_expenses: tuple["estimated_expenses"].to_f,
        total_transactions: tuple["total_transactions"].to_f }
    else
      nil
    end
  end

  def category_overview(budget_id)
    sql = <<~SQL
      SELECT c.id,
             c.name,
             c.amount AS total_allocated,
             SUM(t.amount) AS total_spent,
             (c.amount - SUM(t.amount)) AS remaining
      FROM categories AS c
      LEFT JOIN transactions AS t
      ON c.id = t.category_id
      JOIN budgets AS b ON b.id = c.budget_id
      GROUP BY c.id, c.name, c.amount, b.id 
      HAVING b.id = $1
      ORDER BY c.id ASC;
    SQL

    result = query(sql, budget_id)

    result.map do |tuple|
      { id: tuple["id"],
        name: tuple["name"],
        total_allocated: tuple["total_allocated"],
        total_spent: tuple["total_spent"],
        remaining: tuple["remaining"] }
    end
  end

  def fetch_category(category_id)
    sql = "SELECT * FROM categories WHERE id = $1;"
    result = query(sql, category_id)
    tuple = result.first

    { id: tuple["id"].to_i,
      budget_id: tuple["budget_id"].to_i,
      name: tuple["name"],
      amount: tuple["amount"].to_f }
  end

  def add_category(category_name, category_amount)
    sql = <<~SQL
      INSERT INTO categories
        (budget_id, name, amount)
      VALUES 
        ($1, $2, $3);
    SQL

    category_id = 1
    result = query(sql, category_id, category_name, category_amount)
  end

  def edit_category(id, name, amount)
    sql = "UPDATE categories SET name = $1, amount = $2 WHERE id = $3;"
    query(sql, name, amount, id)
  end

  def expenses_total(budget_id)
    sql = "SELECT SUM(amount) FROM categories WHERE budget_id = $1"

    result = query(sql, budget_id)
    result.first["sum"]
  end

  def all_transactions(budget_id)
    sql = <<~SQL
      SELECT t.amount, 
             t.description, 
             TO_CHAR(t.date :: DATE, 'mm/dd/yyyy') AS date, 
             TO_CHAR(date :: TIME, 'HH24:MI:SS') AS time, 
             c.name
        FROM categories AS c
        JOIN transactions AS t
          ON c.id = t.category_id
        WHERE c.budget_id = $1
        ORDER BY date DESC, time DESC;
    SQL
    result = query(sql, budget_id)

    result.map do |tuple|
      { amount: tuple["amount"],
        description: tuple["description"],
        date: tuple["date"],
        time: tuple["time"],
        category_name: tuple["name"] }
    end
  end

  def fetch_category_transactions(cat_id)
    sql = <<~SQL
      SELECT id, 
             category_id,
             amount, 
             description, 
             TO_CHAR(date :: DATE, 'mm/dd/yyyy') AS date, 
             TO_CHAR(date :: TIME, 'HH24:MI:SS') AS time
        FROM transactions
        WHERE category_id = $1
        ORDER BY date DESC, time DESC;
    SQL

    result = query(sql, cat_id)

    result.map do |tuple|
      { id: tuple["id"],
        category_id: tuple["category_id"],
        description: tuple["description"],
        amount: tuple["amount"],        
        date: tuple["date"],
        time: tuple["time"] }
    end
  end

  def all_deposits(budget_id)
    sql = <<~SQL
      SELECT amount, 
             TO_CHAR(date_time :: DATE, 'mm/dd/yyyy') AS date,
             TO_CHAR(date_time :: TIME, 'HH24:MI:SS') AS time
        FROM deposits
        WHERE budget_id = $1;
    SQL
    
    result = query(sql, budget_id)
    result.map do |tuple|
      { amount: tuple["amount"].to_f,
        date: tuple["date"],
        time: tuple["time"] }
    end
  end

  def add_deposit(deposit_amount, budget_id)
    update_balance_sql = "UPDATE budgets SET balance=balance + $1 WHERE id = $2"
    add_deposit_sql = "INSERT INTO deposits (budget_id, amount) VALUES ($1, $2);"

    query(update_balance_sql, deposit_amount, budget_id)
    query(add_deposit_sql, budget_id, deposit_amount)
  end

  def delete_budget(budget_id)
    sql = "DELETE FROM budgets WHERE id = $1;"
    query(sql, budget_id)
  end

  def delete_deposit_history(budget_id)
    delete_history_sql = "DELETE FROM deposits WHERE budget_id = $1;"
    reset_balance_sql = "UPDATE budgets SET balance = 0.0 WHERE id = $1;"

    query(delete_history_sql, budget_id)
    query(reset_balance_sql, budget_id)
  end

  def delete_category(category_id)
    sql = "DELETE FROM categories WHERE id = $1"
    query(sql, category_id)
  end

  def add_transaction(category_id, description, amount)
    sql =<<~SQL
      INSERT INTO transactions 
        (category_id, description, amount)
      VALUES ($1, $2, $3);
    SQL
    
    query(sql, category_id, description, amount)
  end

  def create_new_user(username, password, budget_title)
    query("INSERT INTO users (username, password) VALUES ($1, $2);", username, password)
    result = query("SELECT * FROM users WHERE username LIKE $1", username)
    user_id = result.first["id"].to_i
    create_new_budget(user_id, budget_title)
  end

  def fetch_user_credentials(username, password)
    sql = "SELECT username, password FROM users WHERE username LIKE $1 AND password LIKE $2;"
    result = query(sql, username, password)
    
    tuple = result.first
      
    { username: tuple["username"],
      password: tuple["password"] }
  end

  private

  def create_new_budget(user_id, title)
    sql = "INSERT INTO budgets (user_id, title) VALUES ($1, $2);"
    query(sql, user_id, title)
  end

  def query(statement, *params)
    @logger.info "\n\n-->params: \n#{params}\n\n-->statement: \n#{statement}\n" 
    @db.exec_params(statement, params)
  end
end