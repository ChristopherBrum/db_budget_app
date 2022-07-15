DROP TABLE transactions;
DROP TABLE categories;
DROP TABLE deposits;
DROP TABLE budgets;
DROP TABLE users;

CREATE TABLE users (
  id serial PRIMARY KEY,
  username varchar(24) NOT NULL UNIQUE,
  password varchar(50) NOT NULL UNIQUE,
  date_time timestamp DEFAULT now()
);

CREATE TABLE budgets (
  id serial PRIMARY KEY,
  user_id integer NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,
  title text NOT NULL UNIQUE,
  balance numeric(12,2) NOT NULL DEFAULT 0.0
);

CREATE TABLE categories (
  id serial PRIMARY KEY,
  budget_id integer NOT NULL REFERENCES budgets (id) ON DELETE CASCADE,
  name text NOT NULL UNIQUE,
  amount numeric(12,2) NOT NULL
);

CREATE TABLE transactions (
  id serial PRIMARY KEY,
  category_id integer NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
  description text NOT NULL DEFAULT '',
  amount numeric(12,2) NOT NULL DEFAULT 0.00,
  date timestamp DEFAULT now()
);

CREATE TABLE deposits (
  id serial PRIMARY KEY,
  budget_id integer NOT NULL REFERENCES budgets (id) ON DELETE CASCADE,
  amount numeric(12,2) NOT NULL DEFAULT 0.00,
  date_time timestamp NOT NULL DEFAULT now()
);


-- Insert statements if some dummy data is needed

-- INSERT INTO budgets (name, balance) 
--      VALUES ('My Budget');

-- INSERT INTO categories (budget_id, name, amount) 
--      VALUES (1, 'Utilities', 200), 
--             (1, 'Rent', 850), 
--             (1, 'Bills', 265);

-- INSERT INTO transactions (category_id, description, amount)
--      VALUES (1, 'water bill', 65),
--             (1, 'electric bill', 44.65),
--             (2, 'rent for July', 850),
--             (3, 'cell phone bill', 44.44),
--             (3, 'health insurance premium', 87.73),
--             (3, 'netflix subscription', 7.99),
--             (3, 'grammarly subscription', 14.99),
--             (3, 'car insurance premium', 72.41);
