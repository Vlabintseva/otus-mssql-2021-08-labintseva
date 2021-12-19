/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--==================== вложенный запрос ======================--

select
  PersonID
, FullName

from (
			select
			*
			
			from Application.People
			where IsSalesperson = 1
	) p
	left join (
				select
				*
			
				from Sales.Invoices
				where InvoiceDate = '2015-07-04'
		) s
		on s.SalespersonPersonID = p.PersonID
where s.SalespersonPersonID is null

--==================== WITH ======================--

WITH SelesMen as (
						select
						*
			
						from Application.People
						where IsSalesperson = 1
				 ),
	 Sales as (
						select
						*
			
						from Sales.Invoices
						where InvoiceDate = '2015-07-04'	
			  )

select
  PersonID
, FullName

from SelesMen p
	left join Sales s
		on s.SalespersonPersonID = p.PersonID
where s.SalespersonPersonID is null


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

--==================== вложенный запрос ======================--

select
  StockItemID
, StockItemName
, UnitPrice

from Warehouse.StockItems s
	join (
			select
			  min(unitprice) min_price

			from Warehouse.StockItems
		 ) i
		on s.UnitPrice = i.min_price

--==================== WITH ======================--

WITH MinPrice as (
						select
						  min(unitprice) min_price

						from Warehouse.StockItems
				 )

select
  StockItemID
, StockItemName
, UnitPrice

from Warehouse.StockItems s
	join MinPrice i
		on s.UnitPrice = i.min_price


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--==================== вложенный запрос ======================--

select distinct
  CustomerName
, PhoneNumber
, WebsiteURL

from Sales.Customers c
	join (
				select top 5
				  CustomerID
				, transactionamount

				from Sales.CustomerTransactions
				order by
				  transactionamount desc
		 ) t
		on c.CustomerID = t.CustomerID

--==================== WITH ======================--

WITH Top5trans as (
							select top 5
							  CustomerID
							, transactionamount

							from Sales.CustomerTransactions
							order by
							  transactionamount desc
				  )

select distinct
  CustomerName
, PhoneNumber
, WebsiteURL

from Sales.Customers c
	join Top5trans t
		on c.CustomerID = t.CustomerID

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--==================== вложенный запрос ======================--

select distinct
  CityID
, CityName
, PackedByPersonID
, FullName

from sales.Invoices i
	join Sales.InvoiceLines il
		on i.InvoiceID = il.InvoiceID
	join Sales.Customers c
		on i.CustomerID = c.CustomerID
	join Application.Cities ci
		on c.DeliveryCityID = ci.CityID
	join Application.People p
		on i.PackedByPersonID = p.PersonID
	join (
			select top 3
			  StockItemID
			, UnitPrice

			from Warehouse.StockItems
			order by
				UnitPrice desc
		 ) it
		on il.StockItemID = it.StockItemID

--==================== WITH ======================--

WITH Top3Items as (
					select top 3
					  StockItemID
					, UnitPrice

					from Warehouse.StockItems
					order by
						UnitPrice desc
				  )


select distinct
  CityID
, CityName
, PackedByPersonID
, FullName

from sales.Invoices i
	join Sales.InvoiceLines il
		on i.InvoiceID = il.InvoiceID
	join Sales.Customers c
		on i.CustomerID = c.CustomerID
	join Application.Cities ci
		on c.DeliveryCityID = ci.CityID
	join Application.People p
		on i.PackedByPersonID = p.PersonID
	join Top3Items it
		on il.StockItemID = it.StockItemID

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- не делала, поскольку оно опциональное
