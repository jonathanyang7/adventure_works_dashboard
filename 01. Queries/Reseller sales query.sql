SELECT [OrderQuantity] AS Volume,
       SalesAmount * AverageRate AS "Gross Revenue",
       (SalesAmount - TotalProductCost) * AverageRate AS "Net Revenue",
       TotalProductCost * AverageRate as "Cost of Sales",
       product.Category AS "Product Category",
       geography.City,
       geography.SalesTerritoryCountry AS "Country",
       reseller.BusinessType AS "Reseller Type",
       reseller.ResellerName AS "Reseller Name",
       reseller.ResellerLine AS "Reseller Focus",
       Salesteam.Name AS "Salesperson Contact",
       Dates.FiscalYear AS "Fiscal Year"
FROM [AdventureWorksDW2022].[dbo].[FactResellerSales] rs
    JOIN -- Currency data
    [AdventureWorksDW2022].[dbo].[FactCurrencyRate] cr
        ON (
               cr.CurrencyKey = rs.CurrencyKey
               AND cr.DateKey = rs.OrderDateKey
           )
    JOIN -- Product data
    (
        SELECT [ProductKey],
               ps.[EnglishProductCategoryName] AS Category
        FROM [AdventureWorksDW2022].[dbo].[DimProduct] p
            JOIN -- Add category and subcategory data to product table 
            (
                SELECT [ProductSubcategoryKey],
                       pc.[EnglishProductCategoryName]
                FROM [AdventureWorksDW2022].[dbo].[DimProductSubcategory] ps
                    JOIN [AdventureWorksDW2022].[dbo].[DimProductCategory] pc
                        ON ps.ProductCategoryKey = pc.ProductCategoryKey
            ) ps
                ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
    ) product
        ON product.ProductKey = rs.ProductKey
    JOIN -- Reseller data
    (
        (SELECT [ResellerKey],
                [GeographyKey],
                [BusinessType],
                [ResellerName],
                [ProductLine] AS ResellerLine
         FROM [AdventureWorksDW2022].[dbo].[DimReseller])
    ) reseller
        ON reseller.ResellerKey = rs.ResellerKey
    JOIN -- Salesperson data
    (
        SELECT [EmployeeKey],
               CONCAT([FirstName], ' ', [LastName]) AS Name,
               DATEDIFF(year, [HireDate], '2013/12/31') AS TenureYears
        FROM [AdventureWorksDW2022].[dbo].[DimEmployee]
        WHERE SalesPersonFlag = 1
    ) SalesTeam
        ON SalesTeam.EmployeeKey = rs.EmployeeKey
    JOIN -- Dates data
    (
        SELECT [DateKey],
               CONCAT('FY', RIGHT([FiscalYear], 2)) AS FiscalYear
        FROM [AdventureWorksDW2022].[dbo].[DimDate]
    ) Dates
        ON Dates.DateKey = rs.OrderDateKey
    JOIN -- Geographical data
    (
        SELECT [City],
               [GeographyKey],
               t.SalesTerritoryCountry
        FROM [AdventureWorksDW2022].[dbo].[DimGeography] g
            JOIN [AdventureWorksDW2022].[dbo].[DimSalesTerritory] t
                ON t.SalesTerritoryKey = g.SalesTerritoryKey
    ) geography
        ON geography.GeographyKey = reseller.GeographyKey
