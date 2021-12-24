/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/


with customers as (
					SELECT
							CustomerID
						   , SUBSTRING( CustomerName, CHARINDEX( '(', CustomerName, 1 ) + 1 , ( CAST(CHARINDEX( ')', CustomerName, 1 ) AS INT)
						   -  CAST(CHARINDEX( '(', CustomerName, 1 ) AS INT)-1)) clarification
					FROM Sales.Customers
					where 1=1
						and CustomerID between 2 and 6
					) 

, itog as		 (
				select 
				  InvoiceID
				, cast(CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(InvoiceDate)-1),InvoiceDate),104) as date) InvoiceMonth
				, c.clarification

				from Sales.Invoices i
					join customers c
						on i.CustomerID = c.customerid
				 )

select 
  convert(varchar(10), InvoiceMonth, 104) InvoiceMonth
, [Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND]

from (
select *
from (select InvoiceMonth,  clarification from itog) p
	pivot (count(clarification) for clarification in ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])) pvt
) p


/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select CustomerName, AddressLine from Sales.Customers
unpivot ( addressline  for CustomerName1  in([deliveryaddressline1], [deliveryaddressline2])) p
where CustomerName like '%Tailspin Toys%'

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select CountryID
	  , CountryName
	  , code 
from (
		select CountryID
			  , CountryName
			  , isoalpha3code
			  , CAST(isonumericcode AS nVARCHAR (3)) AS isonumericcode
		FROM Application.Countries
) AS A
unpivot ( Code for isocode  in([isoalpha3code], [isonumericcode] )) p

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/


select
  i.CustomerID
, c.CustomerName
, StockItemID
, UnitPrice
, InvoiceDate

from Sales.Customers c
	cross apply (
			select
			  CustomerID
			, InvoiceID
			, StockItemID
			, InvoiceDate
			, UnitPrice

			from (
					select
					t.*
					, row_number() over (partition by customerid  order by customerid, unitprice desc) rn2
					from (
							select
							p.*
							, row_number() over (partition by customerid, unitprice  order by customerid, unitprice desc) rn1
							from (
									select
									  CustomerID
									, i.InvoiceID
									, StockItemID
									, InvoiceDate
									, UnitPrice
									, row_number() over (partition by customerid, i.InvoiceID, unitprice  order by customerid, i.InvoiceID, unitprice) rn

									from Sales.Invoices i
										join Sales.InvoiceLines il
											on i.InvoiceID = il.InvoiceID
								 ) p
							where 1=1
								and rn = 1
						 ) t
					where rn1 = 1
				) o
			where rn2 in (1, 2)
				and o.CustomerID = c.CustomerID
				) i
order by i.CustomerID, unitprice desc
