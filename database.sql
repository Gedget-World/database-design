-- User Table

CREATE TABLE user (
  user_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE
    CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  is_email_verified BOOLEAN DEFAULT FALSE,
  phone_number VARCHAR(15) NOT NULL,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  is_user_active BOOLEAN DEFAULT TRUE,
  password VARCHAR(100) NOT NULL,

  -- Notifications
  email_notifications BOOLEAN DEFAULT FALSE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  push_notifications BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_address (
  address_id SERIAL PRIMARY KEY,
  type VARCHAR(50) NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  address_line1 VARCHAR(100) NOT NULL,
  address_line2 VARCHAR(100),
  city VARCHAR(50) NOT NULL,
  state VARCHAR(50) NOT NULL,
  postal_code VARCHAR(10) NOT NULL,
  country VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  user_id INT REFERENCES user(user_id)
);

CREATE TABLE payment_method (
  payment_id SERIAL PRIMARY KEY,
  user_id INT REFERENCES user(user_id),
  type VARCHAR(50) NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  card_number VARCHAR(16) NOT NULL,
  cardholder_name VARCHAR(100) NOT NULL,
  expiration_month VARCHAR(2) NOT NULL,
  expiration_year VARCHAR(4) NOT NULL,
  cvv VARCHAR(4) NOT NULL,
  card_type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

CREATE TABLE product (
  product_id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  name_slug VARCHAR(100) NOT NULL,
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
  collection_id INT REFERENCES collection(collection_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order tables
CREATE TABLE order (
  order_id SERIAL PRIMARY KEY,
  user_id INT REFERENCES user(user_id),
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
  status VARCHAR(50) NOT NULL,
  message TEXT,
  updated_by TEXT,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_item (
  order_item_id SERIAL PRIMARY KEY,
  order_id INT REFERENCES order(order_id),
  product_id INT REFERENCES product(product_id),
  quantity INT NOT NULL CHECK (quantity > 0),
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE order_address (
  order_address_id SERIAL PRIMARY KEY,
  order_id INT REFERENCES order(order_id),
  address_id INT REFERENCES user_address(address_id),
  type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_payment (
  order_payment_id SERIAL PRIMARY KEY,
  order_id INT REFERENCES order(order_id),
  payment_id INT REFERENCES payment_method(payment_id),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount >= 0),
  payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(50) NOT NULL
);

CREATE TABLE coupon (
  coupon_id SERIAL PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE,
  discount_type VARCHAR(50) NOT NULL,
  discount_value DECIMAL(10, 2) NOT NULL CHECK (discount_value >= 0),
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wishlist Table
CREATE TABLE wishlist (
  wishlist_id SERIAL PRIMARY KEY,
  user_id INT REFERENCES user(user_id),
  product_id INT REFERENCES product(product_id),
  price_when_added DECIMAL(10, 2) NOT NULL CHECK (price_when_added >= 0),

  -- Notification
  price_drop_alert BOOLEAN DEFAULT FALSE,
  price_drop_alert_threshold DECIMAL(10, 2) NOT NULL CHECK (price_drop_alert_threshold >= 0),
  stock_alert BOOLEAN DEFAULT FALSE,
  review_alert BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product Ratings
CREATE TABLE product_rating (
  rating_id SERIAL PRIMARY KEY,
  user_id INT REFERENCES user(user_id),
  product_id INT REFERENCES product(product_id),
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review TEXT,

  -- Detailed Rating Breakdown
  buy_quantity INT NOT NULL CHECK (buy_quantity > 0),
  value DECIMAL(10, 2) NOT NULL CHECK (value >= 0),
  design DECIMAL(10, 2) NOT NULL CHECK (design >= 0),
  comfort DECIMAL(10, 2) NOT NULL CHECK (comfort >= 0),
  durability DECIMAL(10, 2) NOT NULL CHECK (durability >= 0),

  -- Purchase Information
  verified_purchase BOOLEAN DEFAULT FALSE,
  purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  would_recommend BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);