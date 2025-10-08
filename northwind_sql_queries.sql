/**************************************************
АНАЛИТИЧЕСКИЕ ЗАПРОСЫ NORTHWIND 
Для портфолио Data Analyst
Автор: [Сергей Толмачев]
Описание: Комплексный анализ продаж, клиентов и товаров
**************************************************/

/*************************
РАЗДЕЛ 1: БАЗОВЫЕ JOIN И АГРЕГАЦИЯ
*************************/

-- Написать запрос, который соединяет orders и customers, чтобы видеть не только номер заказа,
--  но и название компании-заказчика.

SELECT o.order_id, o.order_date, c.company_name
From orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LIMIT 10;

-- Новая задача:
-- Посчитать общую выручку по каждому заказу.

SELECT 
    o.order_id, 
    o.order_date,
    SUM(od.quantity * od.unit_price) as order_total
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.order_id, o.order_date
ORDER BY order_total DESC
LIMIT 10;

-- Задача:
-- Модифицировать запрос, чтобы показывать:

-- номер заказа
-- дату заказа
-- название компании-заказчика
-- общую сумму заказа

SELECT 
    o.order_id, 
    o.order_date,
    c.company_name,
    SUM(od.quantity * od.unit_price) as order_total
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN customers c ON o.customer_id = c.customer_id
GROUP BY o.order_id, o.order_date, c.company_name
ORDER BY order_total DESC
LIMIT 10;


/*************************
РАЗДЕЛ 2: ДЕТАЛИЗАЦИЯ И АНАЛИЗ ТОВАРОВ
*************************/

-- Задача: Показать полную детализацию заказа
-- Номер и дата заказа
-- Компания-заказчик
-- Название товара, количество, цена за единицу
-- Общая стоимость по каждой позиции

SELECT 
    o.order_id,
    o.order_date,
    c.company_name,
    p.product_name,
    od.quantity,
    od.unit_price,
    (od.quantity * od.unit_price) as position_total  
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON od.product_id = p.product_id  
ORDER BY o.order_id
LIMIT 10;


/*************************
РАЗДЕЛ 3: ПРОДВИНУТЫЕ ТЕХНИКИ (ОКОННЫЕ ФУНКЦИИ, CTE)
*************************/

-- Бизнес-вопрос: "Какова динамика продаж по месяцам? В какие месяцы мы зарабатываем больше всего?"

-- Нужно сгруппировать данные не по заказам, а по периодам времени.

SELECT 
    EXTRACT(YEAR FROM o.order_date) as year,
    EXTRACT(MONTH FROM o.order_date) as month,
    SUM(od.quantity * od.unit_price) as monthly_revenue
FROM orders o
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY year, month
ORDER BY year, month;

-- Бизнес-вопрос: "Какие товары приносят нам больше всего денег? А какие продаются в наибольших количествах?"

-- Нужно проанализировать товары по двум метрикам:
-- По выручке (сумма продаж)
-- По количеству (штуки)

SELECT
    p.product_id,
    p.product_name,
    SUM(od.quantity * od.unit_price) as order_total,
    SUM(od.quantity) as total_sold
FROM products p
INNER JOIN order_details od ON p.product_id = od.product_id
GROUP BY     p.product_id, p.product_name
ORDER BY order_total DESC
LIMIT 5;

-- Бизнес-вопрос: "Насколько важен каждый товар для нашего бизнеса в процентах?"

SELECT
    p.product_id,
    p.product_name,
    SUM(od.quantity * od.unit_price) as product_revenue,
    SUM(SUM(od.quantity * od.unit_price)) OVER() as total_company_revenue,
    (SUM(od.quantity * od.unit_price) * 100.0 / 
     SUM(SUM(od.quantity * od.unit_price)) OVER()) as percent_in_revenue
FROM products p
INNER JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_id, p.product_name
ORDER BY product_revenue DESC
LIMIT 5;

-- рефакторинг

WITH product_sales AS (
    SELECT     
        p.product_id as product_id,
        p.product_name as product_name,
        SUM(od.quantity * od.unit_price) as product_revenue 
    FROM products p
    INNER JOIN order_details od ON p.product_id = od.product_id
    GROUP BY p.product_id, p.product_name
)
SELECT
    product_id,
    product_name,
    product_revenue,
    SUM(product_revenue) OVER() as total_company_revenue,
    (product_revenue * 100.0 / SUM(product_revenue) OVER()) as percent_in_revenue
FROM product_sales
ORDER BY product_revenue DESC
LIMIT 5;


-- Бизнес-вопрос: "На сколько процентов выросли или упали продажи в этом месяце 
-- по сравнению с предыдущим?"

WITH monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date) as year,
        EXTRACT(MONTH FROM o.order_date) as month,
        SUM(od.quantity * od.unit_price) as monthly_revenue
    FROM orders o
    INNER JOIN order_details od ON o.order_id = od.order_id
    GROUP BY year, month
)
SELECT
    year,
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER(ORDER BY year, month) as prev_month_revenue,
    monthly_revenue - LAG(monthly_revenue) OVER(ORDER BY year, month) as absolute_change,
    ((monthly_revenue - LAG(monthly_revenue) OVER(ORDER BY year, month)) * 100.0 / 
     LAG(monthly_revenue) OVER(ORDER BY year, month)) as percent_change
FROM monthly_sales
ORDER BY year, month;

-- Бизнес-вопрос: "Какие клиенты делают самые крупные заказы в среднем? Кто наши VIP-клиенты по среднему чеку?"

-- Что нужно рассчитать:
-- Общее количество заказов для каждого клиента
-- Общую сумму всех заказов для каждого клиента
-- Среднюю сумму заказа (общая сумма / количество заказов)
-- Ранжировать клиентов по средней сумме заказа

SELECT
    c.customer_id,
    c.company_name,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(od.quantity * od.unit_price) as order_total,
    SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id) as avg_order
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY avg_order DESC
LIMIT 5;

-- Добавим категоризацию клиентов по среднему чеку:

SELECT
    c.customer_id,
    c.company_name,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(od.quantity * od.unit_price) as order_total,
    SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id) as avg_order,
    CASE 
        WHEN SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id) > 4000 THEN 'VIP'
        WHEN SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id) > 3000 THEN 'Premium' 
        ELSE 'Standard'
    END as customer_segment
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY avg_order DESC
LIMIT 10;

-- рефакторинг

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.company_name,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(od.quantity * od.unit_price) as total_revenue,
        SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id) as avg_order_value
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id, c.company_name
)
SELECT
    customer_id,
    company_name,
    order_count,
    total_revenue,
    avg_order_value,
    CASE 
        WHEN avg_order_value > 4000 THEN 'VIP'
        WHEN avg_order_value > 3000 THEN 'Premium' 
        ELSE 'Standard'
    END as customer_segment
FROM customer_metrics
ORDER BY avg_order_value DESC
LIMIT 10;

/*************************
РАЗДЕЛ 4: КЛИЕНТСКАЯ АНАЛИТИКА И СЛОЖНЫЕ КЕЙСЫ
*************************/

-- Выбор только vip и premium клиентов


WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.company_name,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(od.quantity * od.unit_price) as total_revenue,
        SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id) as avg_order_value
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    INNER JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id, c.company_name
)
SELECT
    customer_id,
    company_name,
    order_count,
    total_revenue,
    avg_order_value,
    CASE 
        WHEN avg_order_value > 4000 THEN 'VIP'
        WHEN avg_order_value > 3000 THEN 'Premium' 
        ELSE 'Standard'
    END as customer_segment
FROM customer_metrics
Where avg_order_value > 3000
ORDER BY avg_order_value DESC
LIMIT 10;

-- Запрос с HAVING (VIP-клиенты выручкка более 50 000 и более 5 заказов):

SELECT
    c.customer_id,
    c.company_name,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(od.quantity * od.unit_price) as total_revenue,
    SUM(od.quantity * od.unit_price) / COUNT(DISTINCT o.order_id) as avg_order_value
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name
HAVING SUM(od.quantity * od.unit_price) > 50000  -- Выручка > 50,000
   AND COUNT(DISTINCT o.order_id) > 5            -- Более 5 заказов
ORDER BY total_revenue DESC;

-- Иерархия сотрудников (Self Join)
-- Бизнес-вопрос: "Кто кому подчиняется в организации?"
-- Цель: Показать структуру подчинения сотрудников

SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name as Employee,
    e.title as EmployeeTitle,
    m.first_name || ' ' || m.last_name as Manager,
    m.title as ManagerTitle
FROM employees e
LEFT JOIN employees m ON e.reports_to = m.employee_id
ORDER BY e.employee_id;

-- Анализ лояльных клиентов с фильтрацией по дате
-- Бизнес-вопрос: "Какие клиенты делают больше всего заказов после определенной даты?"
-- Назначение: Комплексная фильтрация (WHERE + HAVING) и анализ клиентской базы
-- Особенности: 
--   - Фильтрация заказов по дате (WHERE)
--   - Агрегация с несколькими метриками
--   - Фильтрация результатов агрегации (HAVING)
--   - Многоуровневая сортировка

SELECT
    c.customer_id,
    c.company_name,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(od.quantity * od.unit_price) as total_spent,
    AVG(od.quantity * od.unit_price) as avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
WHERE o.order_date >= '1994-12-31'
GROUP BY c.customer_id, c.company_name
HAVING COUNT(DISTINCT o.order_id) > 10
ORDER BY total_orders DESC, total_spent DESC;

-- Бизнес-вопрос: "Каков возраст сотрудников и как он распределен?"
-- Назначение: Работа с датами и расчет возраста
-- Особенности: 
--   - Функция AGE() для расчета интервала
--   - EXTRACT() для получения лет из интервала
--   - CURRENT_DATE для текущей даты
SELECT
    first_name,
    last_name,
    title,
    birth_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) as age
FROM employees
ORDER BY age DESC;

-- Скорректированное форматирование

SELECT
    first_name || ' ' || last_name as full_name,
    title,
    birth_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) as age,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) > 60 THEN 'Старше 60'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) > 50 THEN '51-60'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) > 40 THEN '41-50'
        ELSE 'До 40'
    END as age_group
FROM employees
ORDER BY age DESC;

-- Комплексный анализ эффективности сотрудников
-- Бизнес-вопрос: "Как оценить эффективность сотрудников по нескольким метрикам?"
-- Назначение: Комбинирование всех изученных техник в одном запросе
-- Особенности: 
--   - CTE для подготовки данных
--   - LEFT JOIN для учета сотрудников без заказов
--   - Множественная агрегация
--   - Оконная функция RANK() для ранжирования
--   - CASE для категоризации
--   - Комплексная бизнес-логика

WITH employee_stats AS (
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name as employee_name,
        COUNT(o.order_id) as total_orders,
        SUM(od.quantity * od.unit_price) as total_revenue,
        CASE 
            WHEN COUNT(o.order_id) > 0 
            THEN SUM(od.quantity * od.unit_price) / COUNT(o.order_id)
            ELSE 0 
        END as avg_order_value
    FROM employees e
    LEFT JOIN orders o ON e.employee_id = o.employee_id
    LEFT JOIN order_details od ON o.order_id = od.order_id
    GROUP BY e.employee_id, e.first_name, e.last_name
)
SELECT
    employee_name,
    total_orders,
    total_revenue,
    avg_order_value,
    RANK() OVER(ORDER BY total_revenue DESC) as revenue_rank,
    CASE
        WHEN total_orders > 200 THEN 'High Volume'
        WHEN total_orders > 150 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END as volume_category
FROM employee_stats
ORDER BY revenue_rank;