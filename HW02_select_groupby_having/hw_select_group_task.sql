/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select
  StockItemID
, StockItemName

from WideWorldImporters.Warehouse.StockItems
where StockItemName like '%urgent%'
		or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select distinct	-- подзапрос нужен здесь для вывода уникальных поставщиков, поскольку выборка производится из заказов, где может быть не один заказ от одного поставщика
  SupplierID
, SupplierName

from (
		select
		  s.SupplierID
		, s.SupplierName

		from WideWorldImporters.Purchasing.PurchaseOrders o
			right join WideWorldImporters.Purchasing.Suppliers s
				on o.SupplierID = s.SupplierID
		where o.SupplierID is null
	) o

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select
*
from (
		select
		  o.OrderID
		, OrderDate
		, datename(month, OrderDate)		as Month
		, datename(quarter, OrderDate)		as Quarter 
		, case
			when month(orderdate) between 1 and 4 then 'First'
			when month(orderdate) between 5 and 8 then 'Second'
			else 'Third'
		  end as 'Third_of_the_year'
		, CustomerName

		from WideWorldImporters.Sales.Orders o
			join WideWorldImporters.Sales.OrderLines l
				on o.OrderID = l.OrderID
			join WideWorldImporters.Sales.Customers c
				on o.CustomerID = c.CustomerID
		where (UnitPrice > 100 or Quantity > 20) and o.PickingCompletedWhen is not null
	) o
order by
  Quarter
, Third_of_the_year
, OrderDate

--============================== Постраничная выборка =================================--
--============================== Постраничная выборка =================================--
--============================== Постраничная выборка =================================--

select
*
from (
		select
		  o.OrderID
		, OrderDate
		, datename(month, OrderDate)		as Month
		, datename(quarter, OrderDate)		as Quarter 
		, case
			when month(orderdate) between 1 and 4 then 'First'
			when month(orderdate) between 5 and 8 then 'Second'
			else 'Third'
		  end as 'Third_of_the_year'
		, CustomerName

		from WideWorldImporters.Sales.Orders o
			join WideWorldImporters.Sales.OrderLines l
				on o.OrderID = l.OrderID
			join WideWorldImporters.Sales.Customers c
				on o.CustomerID = c.CustomerID
		where (UnitPrice > 100 or Quantity > 20) and o.PickingCompletedWhen is not null
	) o
order by
  Quarter
, Third_of_the_year
, OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select
  DeliveryMethodName
, ExpectedDeliveryDate
, SupplierName
, FullName

from WideWorldImporters.Purchasing.PurchaseOrders o
	join WideWorldImporters.Purchasing.Suppliers s
		on o.SupplierID = s.SupplierID
	join WideWorldImporters.Application.DeliveryMethods d
		on o.DeliveryMethodID = d.DeliveryMethodID
	join WideWorldImporters.Application.People p
		on o.ContactPersonID = p.PersonID
where ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
		and (DeliveryMethodName like 'Air Freight' or DeliveryMethodName like 'Refrigerated Air Freight')
		and IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers
*/


select
  OrderDate
, CustomerName
, FullName as SalespersonPersonName

from wideworldimporters.Sales.Orders s
	join wideworldimporters.Sales.Customers c
		on s.CustomerID = c.CustomerID
	join WideWorldImporters.Application.People p
		on s.SalespersonPersonID = p.PersonID
order by OrderDate desc
OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct
  o.CustomerID
, CustomerName
, PhoneNumber

from wideworldimporters.Sales.Orders o
	join wideworldimporters.Sales.Customers c
		on o.CustomerID = c.CustomerID
	join wideworldimporters.Sales.OrderLines l
		on o.OrderID = l.OrderID
	join WideWorldImporters.Warehouse.StockItems i
		on l.StockItemID = i.StockItemID
where StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
  Year
, Month
, avg(UnitPrice) avg_unit_price
, sum(Quantity*UnitPrice) sum_sale

from (
		select 
		  DATEPART(year, InvoiceDate) year
		, MONTH(InvoiceDate) month
		, i.orderid
		, StockItemID
		, Quantity
		, UnitPrice

		from wideworldimporters.Sales.Invoices i 
			join wideworldimporters.Sales.OrderLines l
				on i.OrderID = l.OrderID
	) p
group by
  year
, month
order by
  year
, month

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select
  Year
, Month
, sum(Quantity*UnitPrice) sum_sale

from (
		select 
		  DATEPART(year, InvoiceDate) year
		, MONTH(InvoiceDate) month
		, i.orderid
		, StockItemID
		, Quantity
		, UnitPrice

		from wideworldimporters.Sales.Invoices i 
			join wideworldimporters.Sales.OrderLines l
				on i.OrderID = l.OrderID
	) p
group by
  year
, month
having
  sum(Quantity*UnitPrice) > 10000
order by
  year
, month

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--select top 2 * from wideworldimporters.Sales.Orders
--select top 2 * from wideworldimporters.Sales.OrderLines where StockItemID = 164
--select top 2 * from wideworldimporters.Sales.Invoices
--select top 2 * from WideWorldImporters.Warehouse.StockItems where StockItemID = 164
--select top 2 * from wideworldimporters.Sales.Customers

select
  a.*
, OrderDate
from (
		select
		  Year
		, Month
		, p.StockItemID
		, max(StockItemName) StockItemName
		, sum(Quantity*UnitPrice) sum_sale
		, sum(Quantity) sum_qnty

		from (
				select
				  DATEPART(year, InvoiceDate) year
				, MONTH(InvoiceDate) month
				, i.orderid
				, l.StockItemID
				, StockItemName
				, Quantity
				, l.UnitPrice

				from wideworldimporters.Sales.Invoices i 
					join wideworldimporters.Sales.OrderLines l
						on i.OrderID = l.OrderID
					join WideWorldImporters.Warehouse.StockItems s
						on l.StockItemID = s.StockItemID
			) p
		group by
		  year
		, month
		, p.StockItemID
		having
		  sum(Quantity) < 50
	) a
	join (
			select *
			from (
					select 
					  b.*
					, ROW_NUMBER() over (partition by StockItemID order by StockItemID, OrderDate) as rn
					from (
							select distinct
							  StockItemID
							, OrderDate

							from wideworldimporters.Sales.OrderLines l
								join wideworldimporters.Sales.Orders o
									on l.OrderID = o.OrderID
						) b
				) p
			where rn = 1

		) o
		on a.StockItemID = o.StockItemID


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
