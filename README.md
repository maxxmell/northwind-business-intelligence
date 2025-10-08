# 🏢 Northwind Traders - Business Intelligence Solution

![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=Power%20BI&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)

## 📊 О проекте
BI-решение для анализа продаж на основе учебной базы данных **Northwind Traders**.

## 🗃️ База данных

- **Оригинальная база**: Microsoft Northwind Traders (учебная база)
- **PostgreSQL порт**: [pthom/northwind_psql](https://github.com/pthom/northwind_psql)
- **Модификации**: Развернута на Raspberry Pi с настройкой удаленного доступа

*Этот проект фокусируется на аналитической части, а не на создании БД*

## 🛠 Технологии
- **Визуализация**: Power BI
- **Аналитика**: 15+ SQL запросов разной сложности

## 📁 Структура проекта
northwind-business-intelligence/
├── 📄 README.md # Главное описание
├── 📁 psql/ # SQL запросы и анализ
│ ├── 📄 northwind_sql_queries.sql # 15+ аналитических запросов
│ └── 📄 query_categories.md # Классификация запросов
├── 📁 powerbi/ # Визуализации и дашборд
└── 📁 documentation/ # Дополнительная документация

## 🔍 SQL Аналитика

Проект содержит комплексные SQL запросы для анализа бизнес-метрик:

- **Базовые JOIN и агрегация** - основы работы с данными
- **Оконные функции** - расчет долей и ранжирование  
- **CTE и сложные запросы** - многоэтапный анализ
- **Бизнес-сегментация** - клиенты, товары, сотрудники

[Подробнее о SQL запросах](./psql/query_categories.md)
[Просмотреть все запросы](./psql/northwind_sql_queries.sql)
