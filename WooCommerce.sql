- =====================================================================
-- Select and Store the ID of an Existing Product
-- =====================================================================

SET @selected_product_id = (
    SELECT ID
    FROM wp_posts
    WHERE post_type = 'product'
    ORDER BY ID DESC
    LIMIT 1
);


-- =====================================================================
--  Select and Store the ID of an Existing Customer (User who has placed an order)
-- =====================================================================

SET @selected_customer_id = (
    SELECT DISTINCT u.ID
    FROM wp_users AS u
    INNER JOIN wp_postmeta AS pm_customer ON u.ID = pm_customer.meta_value
    INNER JOIN wp_posts AS p ON pm_customer.post_id = p.ID
    WHERE
        pm_customer.meta_key = '_customer_user' 
        AND p.post_type = 'product'          
    ORDER BY u.ID DESC                          
    LIMIT 1
);

-- =====================================================================
--  1: Retrieve a list of all products.
--  This selects the ID, title, and status of all posts classified as 'product'.
-- =====================================================================

SELECT
    ID,
    post_title,
    post_status
FROM
    wp_posts
WHERE
    post_type = 'product';

-- =====================================================================
--  2: Retrieve the details of a specific product by its ID.
-- IMPORTANT: Requires @selected_product_id
-- =====================================================================
SELECT
    p.ID,
    p.post_title,
    p.post_content,
    p.post_status,
    p.post_date,
    pm_price.meta_value AS price,
    pm_sku.meta_value AS sku,
    pm_stock.meta_value AS stock_quantity
FROM
    wp_posts AS p
LEFT JOIN
    wp_postmeta AS pm_price ON p.ID = pm_price.post_id AND pm_price.meta_key = '_price'
LEFT JOIN
    wp_postmeta AS pm_sku ON p.ID = pm_sku.post_id AND pm_sku.meta_key = '_sku'
LEFT JOIN
    wp_postmeta AS pm_stock ON p.ID = pm_stock.post_id AND pm_stock.meta_key = '_stock'
WHERE
    p.ID = @selected_product_id
    AND p.post_type = 'product';

-- =====================================================================
--  3: Retrieve the total number of products.
--  Counts all entries with a post_type of 'product'.
-- =====================================================================
SELECT
    COUNT(ID) AS total_products
FROM
    wp_posts
WHERE
    post_type = 'product';

-- =====================================================================
--  4: Retrieve the average price of all products.
--  Calculates the average of the '_price' meta_value for all products.
-- =====================================================================
SELECT
    AVG(CAST(pm.meta_value AS DECIMAL(10, 2))) AS average_product_price
FROM
    wp_posts AS p
INNER JOIN
    wp_postmeta AS pm ON p.ID = pm.post_id
WHERE
    p.post_type = 'product'
    AND pm.meta_key = '_price'
    AND pm.meta_value REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- =====================================================================
--  5: Retrieve the products sorted by their price in descending order.
--  Lists products from highest price to lowest.
-- =====================================================================
SELECT
    p.ID,
    p.post_title,
    CAST(pm.meta_value AS DECIMAL(10, 2)) AS price
FROM
    wp_posts AS p
INNER JOIN
    wp_postmeta AS pm ON p.ID = pm.post_id
WHERE
    p.post_type = 'product'
    AND pm.meta_key = '_price'
    AND pm.meta_value REGEXP '^[0-9]+(\\.[0-9]+)?$'
ORDER BY
    price DESC;

-- =====================================================================
--  6: Update the price of a specific product.
-- IMPORTANT: Requires @selected_product_id
-- =====================================================================
UPDATE
    wp_postmeta
SET
    meta_value = '1.99'
WHERE
    post_id = @selected_product_id
    AND meta_key = '_price';

-- =====================================================================
--  7: Delete a product from the database.
-- IMPORTANT: Requires @selected_product_id
-- =====================================================================
DELETE FROM
    wp_posts
WHERE
    ID = @selected_product_id
    AND post_type = 'product';

DELETE FROM
    wp_postmeta
WHERE
    post_id = @selected_product_id;

DELETE FROM
    wp_term_relationships
WHERE
    object_id = @selected_product_id;

-- =====================================================================
--  8: Retrieve the list of customers who have placed orders.
--  Identifies users linked to product posts.
-- =====================================================================
SELECT DISTINCT
    u.ID AS customer_id,
    u.user_login,
    u.display_name,
    u.user_email
FROM
    wp_users AS u
INNER JOIN
    wp_postmeta AS pm ON u.ID = pm.meta_value
WHERE
    pm.meta_key = '_customer_user'
    AND pm.post_id IN (SELECT ID FROM wp_posts WHERE post_type = 'product');

-- =====================================================================
--  9: Retrieve the total revenue generated by a specific customer.
-- IMPORTANT: Requires @selected_customer_id 
-- =====================================================================
SELECT
    u.ID AS customer_id,
    u.display_name AS customer_name,
    SUM(CAST(pm_total.meta_value AS DECIMAL(10, 2))) AS total_revenue
FROM
    wp_users AS u
INNER JOIN
    wp_postmeta AS pm_customer ON u.ID = pm_customer.meta_value
INNER JOIN
    wp_posts AS p ON pm_customer.post_id = p.ID
INNER JOIN
    wp_postmeta AS pm_total ON p.ID = pm_total.post_id
WHERE
    pm_customer.meta_key = '_customer_user'
    AND p.post_type = 'product'
    AND p.post_status IN ('wc-completed', 'wc-processing')
    AND pm_total.meta_key = '_order_total'
    AND u.ID = @selected_customer_id 
GROUP BY
    u.ID, u.display_name;

-- =====================================================================
--  10: Retrieve the customer who has placed the highest total order value.
--  Aggregates revenue per customer and finds the top spender.
-- =====================================================================
SELECT
    u.ID AS customer_id,
    u.display_name AS customer_name,
    SUM(CAST(pm_total.meta_value AS DECIMAL(10, 2))) AS total_order_value
FROM
    wp_users AS u
INNER JOIN
    wp_postmeta AS pm_customer ON u.ID = pm_customer.meta_value
INNER JOIN
    wp_posts AS p ON pm_customer.post_id = p.ID
INNER JOIN
    wp_postmeta AS pm_total ON p.ID = pm_total.post_id
WHERE
    pm_customer.meta_key = '_customer_user'
    AND p.post_type = 'product'
    AND p.post_status IN ('wc-completed', 'wc-processing')
    AND pm_total.meta_key = '_order_total'
GROUP BY
    u.ID, u.display_name
ORDER BY
    total_order_value DESC
LIMIT 1;
