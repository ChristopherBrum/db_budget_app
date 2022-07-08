CREATE TABLE budgets (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL UNIQUE,
  balance numeric(12,2) NOT NULL
);

CREATE TABLE categories (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  budget_id integer NOT NULL REFERENCES budgets (id) ON DELETE CASCADE,
  name text NOT NULL UNIQUE,
  amount numeric(12,2) NOT NULL
);

CREATE TABLE transactions (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  category_id integer NOT NULL REFERENCES categories (id),
  description text NOT NULL DEFAULT '',
  amount numeric(12,2) NOT NULL DEFAULT 0.00,
  date timestamp DEFAULT now()
);

-- Insert statements if some dummy data is needed

-- INSERT INTO budgets (name, balance) 
--      VALUES ('My Budget', 2400);

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