CREATE TABLE budgets (
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE,
  balance numeric(12,2) NOT NULL
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
  budget_id integer NOT NULL REFERENCES budgets (id),
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

SELECT c.id,
       c.name, 
       c.amount AS total_allocated, 
       SUM(t.amount) AS total_spent, 
       (c.amount - SUM(t.amount)) AS remaining
FROM categories AS c
LEFT JOIN transactions AS t
  ON c.id = t.category_id
  GROUP BY c.id, c.name, c.amount
  ORDER BY c.id ASC;