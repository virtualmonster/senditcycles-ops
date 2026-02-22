-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Products (Bikes)
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  image_url VARCHAR(255),
  has_sizes BOOLEAN DEFAULT true,
  available_sizes VARCHAR(255) DEFAULT 'S,M,L,XL',
  features TEXT,
  specs TEXT DEFAULT '{}',
  geometry TEXT DEFAULT '{}',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Users
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  role VARCHAR(20) DEFAULT 'user',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_price REAL NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Order Items
CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id),
  quantity INTEGER NOT NULL,
  price_at_purchase REAL NOT NULL
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Insert default categories
INSERT OR IGNORE INTO categories (name, description) VALUES
  ('XC', 'Cross-Country bikes for speed and efficiency'),
  ('Trail', 'Versatile all-purpose trail bikes'),
  ('Downcountry', 'Lightweight descending machines'),
  ('Enduro', 'Long-travel aggressive trail bikes'),
  ('Downhill', 'Gravity-focused extreme downhill bikes');

-- Insert sample products with enhanced photorealistic-style bike images
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (1, 'Swift XC Pro', 'Lightweight cross-country racer built for speed', 1499.99, 15, '/api/images/1-swift-xc-pro.jpg');
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (2, 'TrailBlazer Elite', 'Versatile trail bike for all terrain mayhem', 2199.99, 20, '/api/images/2-trailblazer-elite.jpg');
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (3, 'Alpine Descent', 'Lightweight with big descending capability', 2799.99, 10, '/api/images/3-alpine-descent.jpg');
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (4, 'Beast Mode 29', 'Long travel aggressive enduro machine for tech', 3499.99, 12, '/api/images/4-beast-mode-29.jpg');
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (5, 'Gravity King DH', 'Full suspension gravity focused monster truck', 4299.99, 8, '/api/images/5-gravity-king-dh.jpg');
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (1, 'Cross Lite', 'Budget-friendly cross-country option', 899.99, 25, '/api/images/1-cross-lite.jpg');
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (2, 'Trailmaster 27.5', 'Perfect 27.5" trail ripper for flow', 1899.99, 18, '/api/images/2-trailmaster-27-5.jpg');
INSERT OR IGNORE INTO products (category_id, name, description, price, stock_quantity, image_url) VALUES (4, 'Enduro Plus', 'Feature-packed enduro workhorse', 3099.99, 14, '/api/images/4-enduro-plus.jpg');

-- Create admin user (password: admin123)
-- Hash generated using bcrypt with 10 rounds
INSERT OR IGNORE INTO users (email, password_hash, first_name, last_name, role) VALUES
  ('admin@senditcycles.com', '$2a$10$PCcHVwS.8SPme67BvM9r7uztWnq/HSSM.QLPAuGGpG7nitIUwDveu', 'Admin', 'User', 'admin');
