-- dimensions:
-- Покупатели
CREATE TABLE lab1.dim_customer (
    customer_id INT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    age INT,
    email TEXT,
    country TEXT,
    postal_code TEXT
);

-- Питомцы покупателей
CREATE TABLE lab1.dim_pet (
    pet_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES lab1.dim_customer (customer_id),
    pet_type TEXT,
    pet_name TEXT,
    pet_breed TEXT
);

-- Продавцы
CREATE TABLE lab1.dim_seller (
    seller_id INT PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    country TEXT,
    postal_code TEXT
);

-- Поставщики
CREATE TABLE lab1.dim_supplier (
    supplier_id SERIAL PRIMARY KEY,
    name TEXT,
    contact TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    city TEXT,
    country TEXT
);

-- Магазины
CREATE TABLE lab1.dim_store (
    store_id SERIAL PRIMARY KEY,
    name TEXT,
    location TEXT,
    city TEXT,
    state TEXT,
    country TEXT,
    phone TEXT,
    email TEXT
);

-- Категории товаров
CREATE TABLE lab1.dim_category (
    category_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL
);

-- Подкатегории товаров
CREATE TABLE lab1.dim_subcategory (
    subcategory_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    category_id INT NOT NULL REFERENCES lab1.dim_category (category_id)
);

-- Товары
CREATE TABLE lab1.dim_product (
    product_id INT PRIMARY KEY,
    name TEXT,
    subcategory_id INT NOT NULL REFERENCES lab1.dim_subcategory (subcategory_id),
    price NUMERIC(10, 2),
    weight NUMERIC,
    color TEXT,
    size TEXT,
    brand TEXT,
    material TEXT,
    description TEXT,
    rating NUMERIC(3, 2),
    reviews INT,
    release_date DATE,
    expiry_date DATE
);

-- Факт транзакций
CREATE TABLE lab1.fact_transaction (
    transaction_id BIGINT PRIMARY KEY,
    sale_date DATE NOT NULL,
    customer_id INT NOT NULL REFERENCES lab1.dim_customer (customer_id),
    seller_id INT NOT NULL REFERENCES lab1.dim_seller (seller_id),
    supplier_id INT NOT NULL REFERENCES lab1.dim_supplier (supplier_id),
    store_id INT NOT NULL REFERENCES lab1.dim_store (store_id),
    pet_id INT NOT NULL REFERENCES lab1.dim_pet (pet_id),
    product_id INT NOT NULL REFERENCES lab1.dim_product (product_id),
    sale_quantity INT,
    sale_total_price NUMERIC(12, 2)
);

-- Индексы для ускорения запросов
CREATE INDEX idx_fact_date ON lab1.fact_transaction (sale_date);

CREATE INDEX idx_fact_customer ON lab1.fact_transaction (customer_id);

CREATE INDEX idx_fact_product ON lab1.fact_transaction (product_id);
