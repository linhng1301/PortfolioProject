SELECT *
FROM dbo.CovidDeaths

SELECT *
FROM dbo.CovidVaccinations

-- Select data that we are going to using

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM dbo.CovidDeaths
ORDER BY 1, 2

-- Looking at total cases vs total deaths


SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(CAST(total_deaths AS decimal)/CAST(total_cases AS decimal)) * 100 AS DeathPercentage
FROM dbo.CovidDeaths
WHERE location = 'Vietnam' AND YEAR(date) = '2021'

-- Looking at Total Cases vs Population
SELECT
	location,
	date,
	total_cases,
	population,
	(CAST(total_cases AS decimal)/CAST(population AS decimal)) * 100 AS CasePercentage
FROM dbo.CovidDeaths
WHERE location = 'Vietnam'
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT
	location,
	population,
	MAX(total_cases) AS Highest_Infection_Count,
	MAX((total_cases/population))*100 AS Percent_Population_Infected
FROM dbo.CovidDeaths
GROUP BY location, population
ORDER BY Highest_Infection_Count




-- Showing Countries with Highest Death Count per Population
SELECT
	location,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Break things down by continent
SELECT
	continent,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount

-- Showing continents with the highest death count per population
SELECT
	continent,
	MAX(CAST(total_deaths AS decimal)/CAST(population AS decimal)) * 100 AS Death_Percentage_by_Continent
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Death_Percentage_by_Continent DESC

-- Global numbers
SELECT
	SUM(new_cases) AS Totalcases,
	SUM(new_deaths) AS Totaldeaths,
	CASE
		WHEN SUM(new_cases) <> 0 THEN ROUND((SUM(new_deaths)/SUM(new_cases))*100,3)
		ELSE '0'
	END AS DeathPercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2

-- Looking at Total Population VS Total Vaccinations by country
SELECT
	CD.location,
	CD.population,
	SUM(CAST(CV.new_vaccinations AS decimal)) AS Total_Vaccinations
FROM dbo.CovidDeaths AS CD
JOIN dbo.CovidVaccinations AS CV ON
	CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
GROUP BY CD.location, CD.population

-- Looking at Total Population vs Total Vaccinations
SELECT
	CD.continent,
	CD.location,
	CD.date,
	CD.population,
	CV.new_vaccinations,
	SUM(CAST(CV.new_vaccinations AS decimal)) OVER (Partition by CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS CD
JOIN dbo.CovidVaccinations AS CV ON
	CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2, 3


-- USE CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) 
-- the number of column in cte must be equal to the number of column in select statement below
AS (
SELECT
	CD.continent,
	CD.location,
	CD.date,
	CD.population,
	CV.new_vaccinations,
	SUM(CAST(CV.new_vaccinations AS decimal)) OVER (Partition by CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS CD
JOIN dbo.CovidVaccinations AS CV ON
	CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT * , (RollingPeopleVaccinated/Population)*100
FROM PopVsVac

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated -- after execute, the table will be created in temp database until we close the file
	(Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
	)
INSERT INTO #PercentPopulationVaccinated
SELECT
	CD.continent,
	CD.location,
	CD.date,
	CD.population,
	CV.new_vaccinations,
	SUM(CAST(CV.new_vaccinations AS decimal)) OVER (Partition by CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS CD
JOIN dbo.CovidVaccinations AS CV ON
	CD.location = CV.location
	AND CD.date = CV.date
--WHERE CD.continent IS NOT NULL
--ORDER BY 2, 3
SELECT * , (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
	CD.continent,
	CD.location,
	CD.date,
	CD.population,
	CV.new_vaccinations,
	SUM(CAST(CV.new_vaccinations AS decimal)) OVER (Partition by CD.location ORDER BY CD.location, CD.date) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths AS CD
JOIN dbo.CovidVaccinations AS CV ON
	CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *
FROM dbo.PercentPopulationVaccinated
