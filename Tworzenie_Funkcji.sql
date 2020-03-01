USE AdventureWorks2014
GO -- czyli koniec wsadu

-- Tworzenie funkcji skalarnych
-- Funkcja zwracaj¹ wartoœæ a nie modyfikuj¹ danych
-- funkcje skalarne zwracaj¹ jedn¹ wartoœæ, do tego rolê funkcji odgrywaj¹ procedury sk³adowane

CREATE OR ALTER FUNCTION dbo.ufnGetInitials(@FirstName nvarchar(max), @LastName nvarchar(max))
RETURNS NVARCHAR(2)
AS
BEGIN
	RETURN CONCAT(LEFT(@FirstName, 1), LEFT(@LastName, 1)) -- funkcja CONCAT() radzi sobie z NULL-ami
END
GO

-- w przypdku funkcji zawsze nale¿y podawaæ schemat
SELECT dbo.ufnGetInitials('John', 'Smith') AS Initials 
-- wstawienie wartoœci NULL powoduje, ¿e ca³a funkcja równie¿ zaczyna zwracaæ wartoœæ NULL, ¿eby siê tego pozbyæ nale¿y u¿yæ funkcji CONCAT
SELECT dbo.ufnGetInitials(NULL, 'Smith') AS Initials 
-- wartoœci liczbowe s¹ konwertowane na tekstowe
SELECT dbo.ufnGetInitials(1, 'Smith') AS Initials 

-- inne przyk³ady stosowania funkcji skalarnych
SELECT FirstName, LastName, dbo.ufnGetInitials(FirstName, LastName) AS Initials 
FROM Person.Person

SELECT *
FROM Person.Person
WHERE dbo.ufnGetInitials(FirstName, LastName) = 'KA' 

SELECT *
FROM Person.Person
ORDER BY dbo.ufnGetInitials(FirstName, LastName)

/*
UWAGA: u¿ycie funkcji skalarnych w znaczynym stopniu zmniejsza wydajnoœæ zapytañ
*/

-- Sprawdzanie jakie obiekty zosta³y utworzone w danej bazie danych
SELECT *
FROM sys.objects
WHERE type = 'FN'

-- jak przejrzeæ sk³adnie jakiegoœ obiektu
EXEC sp_helptext 'dbo.ufnGetInitials'
GO

-- Stosowanie zmiennych w funkcjach
CREATE OR ALTER FUNCTION dbo.ufnGetProductName(@ProductID INT)
RETURNS NVARCHAR(100)
AS
BEGIN
	DECLARE @ProductName NVARCHAR(100)
	SET @ProductName = (SELECT [Name] FROM Production.Product WHERE ProductID = @ProductID)
	RETURN @ProductName -- na samym koñcu funkcji skalarnej zawsze musi byæ RETURN
END
GO

-- SNIPPET (szablony kodu)
-- ¿eby wkleiæ sobie szabon kodu nale¿y u¿yæ funkcji Ctrl K + Ctrl X


CREATE FUNCTION [dbo].[FunctionName]
(
    @param1 int,
	@param2 int
)
RETURNS INT
AS
BEGIN

    RETURN @param1 + @param2

END
GO

/*******************************************/
-- FUNKCJE TABELARYCZNE, JEDNOWIERSZOWE (inline)
/* Innymi s³owy to sparametryzowane widoki */

CREATE OR ALTER FUNCTION dbo.tvfProductsByCategory(@CategoryID INT)
RETURNS TABLE AS RETURN

	SELECT
		p.ProductID, p.[Name], p.Color,
		ps.ProductSubcategoryID, ps.[Name] AS SubcategoryName, pc.ProductCategoryID, pc.[Name] AS CategoryName
	FROM Production.Product AS p
		JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
		JOIN Production.ProductCategory AS pc ON pc.ProductCategoryID = ps.ProductCategoryID
	WHERE pc.ProductCategoryID = @CategoryID OR @CategoryID IS NULL

GO
	
SELECT * FROM tvfProductsByCategory(4)
GO

-- przekazywanie wielu parametrów do funkcji w tym tak¿e parametrów tablicowych
CREATE OR ALTER FUNCTION dbo.tvfProductsByCategoryAndColor(
	@CategoryID INT,
	@ColorList VARCHAR(MAX)
)
RETURNS TABLE AS RETURN
	SELECT
		p.ProductID, p.[Name], p.Color,
		ps.ProductSubcategoryID, ps.[Name] AS SubcategoryName, pc.ProductCategoryID, pc.[Name] AS CategoryName
	FROM Production.Product AS p
		JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
		JOIN Production.ProductCategory AS pc ON pc.ProductCategoryID = ps.ProductCategoryID
	WHERE (pc.ProductCategoryID = @CategoryID OR @CategoryID IS NULL)
		  AND Color IN(SELECT TRIM([value]) FROM string_split(@ColorList,','))		
GO

/* UWAGA: ¯eby funkcja string_split zdzia³a³¹ compatibility level bazy danych musi byæ 
ustawiony na poziom przynajmniej SQL 2016 */

SELECT * FROM tvfProductsByCategoryAndColor(1, 'Black,Red')
GO

-- lista funkcji tabelarycznych, wystêpuj¹cych w danej bazie danych (inline-owych)
SELECT * FROM sys.objects WHERE type = 'IF'

-- oraz podgl¹d sk³adni tej funkcji
EXEC sp_helptext 'dbo.tvfProductsByCategoryAndColor'
GO

/****************************************************************/
-- FUNKCJE TABELARYCZNE WIELOWIERSZOWE
-- generalnie takich funkcji u¿ywamy tak samo jak funkcji wielowierszowych inline-owych

-- szkielet funkcji: CTRL K + CTR X

CREATE FUNCTION [dbo].[FunctionName]
(
    @param1 int,
    @param2 char(5)
)
RETURNS @returntable TABLE 
(
	[c1] int,
	[c2] char(5)
)
AS
BEGIN
    INSERT @returntable
    SELECT @param1, @param2
    RETURN 
END
GO

-- realny przyk³ad
CREATE OR ALTER FUNCTION dbo.tvfProductsByCategoryAndColorMulti(
	@CategoryID INT,
	@ColorList VARCHAR(MAX))

RETURNS @ResultTable TABLE(
	ProductID INT,
	[Name] Name,
	Color NVARCHAR(15),
	ProductSubcategoryID INT,
	SubcategoryName Name,
	ProductCategoryID INT,
	CategoryName Name)
AS
BEGIN
	INSERT INTO @ResultTable
	SELECT
		p.ProductID, p.[Name], p.Color,
		ps.ProductSubcategoryID, ps.[Name] AS SubcategoryName, pc.ProductCategoryID, pc.[Name] AS CategoryName
	FROM Production.Product AS p
		JOIN Production.ProductSubcategory AS ps ON ps.ProductSubcategoryID = p.ProductSubcategoryID
		JOIN Production.ProductCategory AS pc ON pc.ProductCategoryID = ps.ProductCategoryID
	WHERE (pc.ProductCategoryID = @CategoryID OR @CategoryID IS NULL)
		  AND Color IN(SELECT TRIM([value]) FROM string_split(@ColorList,','))	
	RETURN
END
GO

SELECT * FROM tvfProductsByCategoryAndColorMulti(1, 'Black,Red')
GO