DO $$
BEGIN
    FOR i IN 0..9 LOOP
        EXECUTE format('
            COPY lab1.mock_data FROM %L CSV HEADER',
            CASE WHEN i = 0 THEN '/data/MOCK_DATA.csv'
                 ELSE '/data/MOCK_DATA (' || i || ').csv'
            END
        );
    END LOOP;
END $$;

-- dim_customer
INSERT INTO lab1.dim_customer (customer_id, first_name, last_name, age, email, country, postal_code)
SELECT DISTINCT
    sale_customer_id,
    customer_first_name,
    customer_last_name,
    customer_age,
    customer_email,
    customer_country,
    customer_postal_code
FROM lab1.mock_data
WHERE sale_customer_id IS NOT NULL
ON CONFLICT (customer_id) DO NOTHING;

-- dim_pet (у pet_id SERIAL — дубликатов не будет)
INSERT INTO lab1.dim_pet (customer_id, pet_type, pet_name, pet_breed)
SELECT DISTINCT
    sale_customer_id,
    customer_pet_type,
    customer_pet_name,
    customer_pet_breed
FROM lab1.mock_data
WHERE sale_customer_id IS NOT NULL
  AND customer_pet_name IS NOT NULL;

-- dim_seller
INSERT INTO lab1.dim_seller (seller_id, first_name, last_name, email, country, postal_code)
SELECT DISTINCT
    sale_seller_id,
    seller_first_name,
    seller_last_name,
    seller_email,
    seller_country,
    seller_postal_code
FROM lab1.mock_data
WHERE sale_seller_id IS NOT NULL
ON CONFLICT (seller_id) DO NOTHING;

-- dim_supplier
INSERT INTO lab1.dim_supplier (name, contact, email, phone, address, city, country)
SELECT DISTINCT
    supplier_name,
    supplier_contact,
    supplier_email,
    supplier_phone,
    supplier_address,
    supplier_city,
    supplier_country
FROM lab1.mock_data
WHERE supplier_name IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM lab1.dim_supplier
    WHERE name = mock_data.supplier_name
);

-- dim_store
INSERT INTO lab1.dim_store (name, location, city, state, country, phone, email)
SELECT DISTINCT
    store_name,
    store_location,
    store_city,
    store_state,
    store_country,
    store_phone,
    store_email
FROM lab1.mock_data
WHERE store_name IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM lab1.dim_store
    WHERE name = mock_data.store_name
);

-- dim_category / dim_subcategory
INSERT INTO lab1.dim_category (name)
SELECT DISTINCT product_category
FROM lab1.mock_data
ON CONFLICT (category_id) DO NOTHING;

INSERT INTO lab1.dim_subcategory (name, category_id)
SELECT DISTINCT product_category || ' - ' || product_name,
       c.category_id
FROM lab1.mock_data m
JOIN lab1.dim_category c
  ON m.product_category = c.name
ON CONFLICT (subcategory_id) DO NOTHING;

-- dim_product
INSERT INTO lab1.dim_product (
    product_id, name, subcategory_id, price, weight, color, size,
    brand, material, description, rating, reviews, release_date, expiry_date
)
SELECT DISTINCT
    sale_product_id,
    product_name,
    s.subcategory_id,
    product_price,
    product_weight,
    product_color,
    product_size,
    product_brand,
    product_material,
    product_description,
    product_rating,
    product_reviews,
    TO_DATE(product_release_date, 'MM/DD/YYYY'),
    TO_DATE(product_expiry_date, 'MM/DD/YYYY')
FROM lab1.mock_data m
JOIN lab1.dim_subcategory s ON m.product_name = s.name
WHERE sale_product_id IS NOT NULL
  AND product_name IS NOT NULL
ON CONFLICT (product_id) DO NOTHING;

-- fact_transaction
INSERT INTO lab1.fact_transaction (
    transaction_id, sale_date, customer_id, seller_id,
    supplier_id, store_id, pet_id, product_id,
    sale_quantity, sale_total_price
)
SELECT
    id,
    TO_DATE(sale_date, 'MM/DD/YYYY'),
    sale_customer_id,
    sale_seller_id,
    sup.supplier_id,
    st.store_id,
    p.pet_id,
    sale_product_id,
    sale_quantity,
    sale_total_price
FROM lab1.mock_data m
JOIN lab1.dim_supplier sup ON m.supplier_name = sup.name
JOIN lab1.dim_store st ON m.store_name = st.name
JOIN lab1.dim_pet p ON m.sale_customer_id = p.customer_id
                    AND m.customer_pet_name = p.pet_name
WHERE id IS NOT NULL
ON CONFLICT (transaction_id) DO NOTHING;
