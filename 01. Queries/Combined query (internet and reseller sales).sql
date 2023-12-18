SELECT fs.OrderQuantity AS Volume,
       (fs.SalesAmount * cr.AverageRate) AS SalesUSD,
       ((fs.SalesAmount - fs.TotalProductCost) * cr.AverageRate) AS Net,
       (fs.TotalProductCost * cr.AverageRate) AS Cost,
       p.[EnglishProductName] AS Product,
       p.ProductLine AS Line,
       psc.[EnglishProductCategoryName] AS Category,
       psc.[EnglishProductSubcategoryName] AS SubCategory,
       st.[SalesTerritoryRegion] AS Region,
       st.[SalesTerritoryCountry] AS Country,
       st.[SalesTerritoryGroup] AS Territory,
       d.[FullDateAlternateKey] AS Date,
       d.[MonthNumberOfYear] AS Month,
       d.[CalendarYear],
       d.[FiscalYear],
       CASE
           WHEN fs.Type = 'Internet' THEN
               'Internet Sales'
           ELSE
               'Reseller Sales'
       END AS Type
FROM -- Union of the Reseller and Internet sales tables
(
    SELECT int.OrderQuantity,
           int.SalesAmount,
           int.TotalProductCost,
           int.CurrencyKey,
           int.OrderDateKey,
           int.ProductKey,
           int.SalesTerritoryKey,
           'Internet' AS Type
    FROM [AdventureWorksDW2022].[dbo].[FactInternetSales] int
    UNION ALL
    SELECT rs.OrderQuantity,
           rs.SalesAmount,
           rs.TotalProductCost,
           rs.CurrencyKey,
           rs.OrderDateKey,
           rs.ProductKey,
           rs.SalesTerritoryKey,
           'Reseller' AS Type
    FROM [AdventureWorksDW2022].[dbo].[FactResellerSales] rs
) fs
    JOIN -- Currency data
    [AdventureWorksDW2022].[dbo].[FactCurrencyRate] cr
        ON cr.CurrencyKey = fs.CurrencyKey
           AND cr.DateKey = fs.OrderDateKey
    JOIN -- Product data
    [AdventureWorksDW2022].[dbo].[DimProduct] p
        ON p.ProductKey = fs.ProductKey
    JOIN -- Additional product data
    (
        SELECT psc.ProductSubcategoryKey,
               psc.[EnglishProductSubcategoryName],
               pc.[EnglishProductCategoryName]
        FROM [AdventureWorksDW2022].[dbo].[DimProductSubcategory] psc
            JOIN [AdventureWorksDW2022].[dbo].[DimProductCategory] pc
                ON psc.ProductCategoryKey = pc.ProductCategoryKey
    ) psc
        ON p.ProductSubcategoryKey = psc.ProductSubcategoryKey
    JOIN -- Geographical data
    [AdventureWorksDW2022].[dbo].[DimSalesTerritory] st
        ON st.SalesTerritoryKey = fs.SalesTerritoryKey
    JOIN -- Dates data
    [AdventureWorksDW2022].[dbo].[DimDate] d
        ON d.DateKey = fs.OrderDateKey