-- User Table

CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE
    CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  is_email_verified BOOLEAN DEFAULT FALSE,
  phone_number VARCHAR(20) NOT NULL
    CHECK (phone_number ~ '^[+]?[0-9\s\-\(\)]{10,15}$'),
  is_phone_verified BOOLEAN DEFAULT FALSE,
  is_user_active BOOLEAN DEFAULT TRUE,
  password_hash VARCHAR(255) NOT NULL,

  -- Notifications
  email_notifications BOOLEAN DEFAULT FALSE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  push_notifications BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_address (
  address_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  type VARCHAR(50) NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  address_line1 VARCHAR(100) NOT NULL,
  address_line2 VARCHAR(100),
  city VARCHAR(50) NOT NULL,
  state VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10) NOT NULL,
  country VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE payment_method (
  payment_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  type VARCHAR(50) NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  payment_gateway VARCHAR(50) NOT NULL,
  gateway_payment_id VARCHAR(100),
  cardholder_name VARCHAR(100) NOT NULL,
  card_last_four VARCHAR(4),
  card_type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Products and collections tables
CREATE TABLE collection (
  collection_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  name_slug VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  image TEXT,
  thumbnail_image TEXT,
  average_rating DECIMAL(3, 2) 
    CHECK (average_rating >= 0 AND average_rating <= 5),
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  seo_title VARCHAR(100) NOT NULL,
  seo_description TEXT NOT NULL,
  seo_keywords TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
  product_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  name_slug VARCHAR(100) NOT NULL UNIQUE,
  description TEXT NOT NULL,
  short_description TEXT NOT NULL,
  image TEXT[],
  optimized_image TEXT[],
  thumbnail_image TEXT,
  price DECIMAL(10, 2) NOT NULL 
    CHECK (price >= 0),
  stock_quantity INT NOT NULL 
    CHECK (stock_quantity >= 0),
  average_rating DECIMAL(3, 2) 
    CHECK (average_rating >= 0 AND average_rating <= 5),
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  seo_title VARCHAR(100) NOT NULL,
  seo_description TEXT NOT NULL,
  seo_keywords TEXT NOT NULL,
  tags TEXT[],
  collection_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (collection_id) REFERENCES collection(collection_id) ON DELETE SET NULL
);

-- Order tables
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
  discount DECIMAL(10, 2) NOT NULL CHECK (discount >= 0),
  coupon_code VARCHAR(50),
  shipping_charge DECIMAL(10, 2) NOT NULL CHECK (shipping_charge >= 0),
  tax DECIMAL(10, 2) NOT NULL CHECK (tax >= 0),
  total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),


  -- Return/Exchange Information
  is_returnable BOOLEAN DEFAULT FALSE,
  return_window INT NOT NULL CHECK (return_window >= 0),
  return_requested BOOLEAN DEFAULT FALSE,
  return_reason TEXT,
  return_requested_at TIMESTAMP,
  return_approved BOOLEAN DEFAULT FALSE,
  return_processed_at TIMESTAMP,

  -- Cancellation Information
  is_cancellable BOOLEAN DEFAULT FALSE,
  cancelled_at TIMESTAMP,
  cancelled_by TEXT,
  cancellation_reason TEXT,
  refund_processed BOOLEAN DEFAULT FALSE,
  refund_processed_at TIMESTAMP,
  cancellation_approved BOOLEAN DEFAULT FALSE,
  cancellation_approved_at TIMESTAMP,

  -- Invoice Information
  invoice_number VARCHAR(50),
  invoice_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  invoice_url TEXT,

  -- Analytics Information
  source VARCHAR(50),
  ip_address VARCHAR(50),
  referrer VARCHAR(50),
  
  -- tracking
  status VARCHAR(50) NOT NULL
    CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
  message TEXT,
  updated_by TEXT,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT
);

CREATE TABLE order_item (
  order_item_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL CHECK (quantity > 0),
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

CREATE TABLE order_address (
  order_address_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL,
  address_id INT NOT NULL,
  type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (address_id) REFERENCES user_address(address_id) ON DELETE RESTRICT
);

CREATE TABLE order_payment (
  order_payment_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL,
  payment_id INT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
  payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) NOT NULL
    CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (payment_id) REFERENCES payment_method(payment_id) ON DELETE RESTRICT
);

CREATE TABLE coupon (
  coupon_id SERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  discount_type VARCHAR(50) NOT NULL
    CHECK (discount_type IN ('percentage', 'fixed_amount')),
  discount_value DECIMAL(10, 2) NOT NULL CHECK (discount_value >= 0),
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (end_date > start_date),
  CHECK (
    (discount_type = 'percentage' AND discount_value <= 100) 
    OR discount_type = 'fixed_amount'
  )
);

-- Wishlist Table
CREATE TABLE wishlist (
  wishlist_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  product_id INT NOT NULL,
  price_when_added DECIMAL(10, 2) NOT NULL CHECK (price_when_added >= 0),

  -- Notification
  price_drop_alert BOOLEAN DEFAULT FALSE,
  price_drop_alert_threshold DECIMAL(10, 2) NOT NULL CHECK (price_drop_alert_threshold >= 0),
  stock_alert BOOLEAN DEFAULT FALSE,
  review_alert BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  UNIQUE(user_id, product_id)
);

-- Product Ratings
CREATE TABLE product_rating (
  rating_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL,
  product_id INT NOT NULL,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,

  -- Detailed Rating Breakdown
  buy_quantity INT NOT NULL CHECK (buy_quantity > 0),
  value DECIMAL(3, 2) NOT NULL CHECK (value >= 1 AND value <= 5),
  design DECIMAL(3, 2) NOT NULL CHECK (design >= 1 AND design <= 5),
  comfort DECIMAL(3, 2) NOT NULL CHECK (comfort >= 1 AND comfort <= 5),
  durability DECIMAL(3, 2) NOT NULL CHECK (durability >= 1 AND durability <= 5),

  -- Purchase Information
  verified_purchase BOOLEAN DEFAULT FALSE,
  purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  would_recommend BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  UNIQUE(user_id, product_id)
);

-- Additional Tables for Better Functionality

-- Audit trail table
CREATE TABLE audit_log (
  audit_id SERIAL PRIMARY KEY,
  table_name VARCHAR(50) NOT NULL,
  record_id INTEGER NOT NULL,
  action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
  old_values JSONB,
  new_values JSONB,
  changed_by INTEGER,
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Inventory tracking
CREATE TABLE inventory_log (
  log_id SERIAL PRIMARY KEY,
  product_id INTEGER NOT NULL,
  change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('stock_in', 'stock_out', 'adjustment')),
  quantity_change INTEGER NOT NULL,
  previous_quantity INTEGER NOT NULL,
  new_quantity INTEGER NOT NULL,
  reason TEXT,
  reference_id INTEGER, -- Could reference order_id or other tables
  created_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Shipping information
CREATE TABLE shipping_method (
  shipping_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  base_cost DECIMAL(10,2) NOT NULL CHECK (base_cost >= 0),
  cost_per_kg DECIMAL(10,2) DEFAULT 0 CHECK (cost_per_kg >= 0),
  estimated_days INTEGER NOT NULL CHECK (estimated_days > 0),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order tracking
CREATE TABLE order_tracking (
  tracking_id SERIAL PRIMARY KEY,
  order_id INTEGER NOT NULL,
  status VARCHAR(50) NOT NULL,
  message TEXT,
  location VARCHAR(100),
  tracking_number VARCHAR(100),
  carrier VARCHAR(50),
  updated_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  FOREIGN KEY (updated_by) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Performance Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_active ON users(is_user_active);

CREATE INDEX idx_collection_slug ON collection(name_slug);
CREATE INDEX idx_collection_active ON collection(is_active);
CREATE INDEX idx_collection_featured ON collection(is_featured);

CREATE INDEX idx_products_collection ON products(collection_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_featured ON products(is_featured);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_stock ON products(stock_quantity);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_total ON orders(total);

CREATE INDEX idx_order_items_product ON order_item(product_id);
CREATE INDEX idx_order_items_order ON order_item(order_id);

CREATE INDEX idx_wishlist_user ON wishlist(user_id);
CREATE INDEX idx_wishlist_product ON wishlist(product_id);

CREATE INDEX idx_ratings_product ON product_rating(product_id);
CREATE INDEX idx_ratings_user ON product_rating(user_id);
CREATE INDEX idx_ratings_rating ON product_rating(rating);

CREATE INDEX idx_payment_user ON payment_method(user_id);
CREATE INDEX idx_payment_default ON payment_method(is_default);

CREATE INDEX idx_address_user ON user_address(user_id);
CREATE INDEX idx_address_default ON user_address(is_default);

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at 
BEFORE UPDATE ON users 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at 
BEFORE UPDATE ON products 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at 
BEFORE UPDATE ON orders 
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
