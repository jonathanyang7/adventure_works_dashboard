SELECT [OrderQuantity] AS Volume,
       (SalesAmount * AverageRate) AS "Gross Revenue",
       (SalesAmount - TotalProductCost) * AverageRate AS "Net Revenue",
       TotalProductCost * AverageRate AS "Cost of Sales",
       product.Category AS "Product",
       product.SubCategory AS "Product Sub-category",
       product.ProductLine AS "Product Line",
       customer.Name,
       customer.Gender,
       customer.EnglishOccupation AS Job,
       customer.Territory,
       customer.Country,
       Dates.FiscalYear,
       ROW_NUMBER() OVER (PARTITION BY FiscalYear
                          ORDER BY (SalesAmount - TotalProductCost) * AverageRate DESC
                         ) AS "Yearly Rank"
FROM [AdventureWorksDW2022].[dbo].[FactInternetSales] intsales
    JOIN -- Currency data
    [AdventureWorksDW2022].[dbo].[FactCurrencyRate] cr
        ON (
               cr.CurrencyKey = intsales.CurrencyKey
               AND cr.DateKey = intsales.OrderDateKey
           )
    JOIN -- Product data
    (
        SELECT [ProductKey],
               CASE
                   WHEN ProductLine = 'R' THEN
                       'Road'
                   WHEN ProductLine = 'M' THEN
                       'Mountain'
                   WHEN ProductLine = 'T' THEN
                       'Touring'
                   WHEN ProductLine = 'S' THEN
                       'Standard'
                   ELSE
                       NULL
               END AS ProductLine,
               ps.[EnglishProductSubcategoryName] AS SubCategory,
               ps.[EnglishProductCategoryName] AS Category
        FROM [AdventureWorksDW2022].[dbo].[DimProduct] p
            JOIN
            (
                SELECT [ProductSubcategoryKey],
                       [EnglishProductSubcategoryName],
                       pc.[EnglishProductCategoryName]
                FROM [AdventureWorksDW2022].[dbo].[DimProductSubcategory] ps
                    JOIN [AdventureWorksDW2022].[dbo].[DimProductCategory] pc
                        ON ps.ProductCategoryKey = pc.ProductCategoryKey
            ) ps
                ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    ) product
        ON product.ProductKey = intsales.ProductKey
    JOIN -- Customer data
    (
        SELECT [CustomerKey],
               CONCAT(FirstName, ' ', LastName) AS Name,
               CASE
                   WHEN Gender = 'M' THEN
                       'Male'
                   WHEN Gender = 'F' THEN
                       'Female'
               END AS Gender,
               [EnglishOccupation],
               g.SalesTerritoryCountry AS Country,
               g.SalesTerritoryGroup AS Territory,
               g.SalesTerritoryRegion AS Region
        FROM [AdventureWorksDW2022].[dbo].[DimCustomer] c
            JOIN
            (
                SELECT [GeographyKey],
                       [City],
                       st.SalesTerritoryRegion,
                       st.SalesTerritoryCountry,
                       st.SalesTerritoryGroup
                FROM [AdventureWorksDW2022].[dbo].[DimGeography] g
                    JOIN [AdventureWorksDW2022].[dbo].[DimSalesTerritory] st
                        ON st.SalesTerritoryKey = g.SalesTerritoryKey
            ) g
                ON g.GeographyKey = c.GeographyKey
    ) customer
        ON customer.CustomerKey = intsales.CustomerKey
    JOIN -- Date data
    (
        SELECT [DateKey],
               [FiscalYear]
        FROM [AdventureWorksDW2022].[dbo].[DimDate]
    ) Dates
        ON Dates.DateKey = intsales.OrderDateKey;
