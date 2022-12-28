SELECT *
FROM CovidDeaths 
ORDER BY 3,4

SELECT *
FROM CovidVaccinations
ORDER BY 3,4

/* SELECT DATA THAT WE ARE GOING TO BE USING */

SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM CovidDeaths 
ORDER BY 1,2 

/* LOOKING AT TOTAL CASES VERSUS TOTAL DEATHS.
A PERSON'S CHANCE OF DYING IF CONTRACTED COVID-19. */

SELECT Location, Date, Total_Cases, Total_Deaths, (Total_Deaths/Total_Cases)*100 AS PercentageDead
FROM CovidDeaths 
WHERE Location like '%states%'
ORDER BY 1,2 

/* EXAMINING TOTAL CASES VS. POPULATION 
Running percentage of population infected with Covid-19 */

SELECT Location, Date, Total_Cases, Population, (Total_Cases/Population) * 100 AS RunningPercentageInfected
FROM CovidDeaths 
--WHERE Location LIKE '%states%'
ORDER BY 1,2 

/* EXAMINE COUNTRIES WITH HIGHEST INFECTION RATE OF POPULATION */

SELECT Location, Population, MAX(Total_Cases) AS HighestNumInfected, MAX((Total_Cases/Population)*100) AS HighestPercentageInfected
FROM CovidDeaths
--Where Location LIKE '%states%'
GROUP BY Location, Population
ORDER BY HighestPercentageInfected DESC

/* EXAMINE COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION */
/* We find that when the continent column is Null, the location column is 
populated with the continent data instead of data from a specific country on that continent. 
To properly analyze country data, we must ensure we aren't including data for entire 
continents as single countries.*/

Select Location, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

/* LET'S NOW EXAMINE BY CONTINENT*/

Select Continent, MAX(CAST(Total_Deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

/* EXAMINE GLOBAL CASE AND DEATH NUMBERS*/

SELECT  SUM(New_Cases) AS TotalCases, SUM(CAST(New_Deaths AS INT)) AS TotalDeaths, (SUM(Cast(New_Deaths AS INT))/SUM(New_Cases) *100) AS DeathPercentage
FROM CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1, 2

SELECT Deaths.Location, Deaths.Date, Deaths.New_Cases, Deaths.Population, Vax.new_vaccinations
, SUM(CAST(Vax.New_Vaccinations AS INT)) OVER (Partition BY Deaths.Location ORDER BY Deaths.Location, Deaths.Date) AS RollingNewVax
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON Deaths.Location = Vax.Location
	AND Deaths.Date = Vax.Date
WHERE Deaths.Continent IS NOT NULL
ORDER BY 1,2 


/* USE CTE */

WITH Pop_vs_Vax (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vax.new_vaccinations
, SUM(CAST(Vax.New_Vaccinations AS INT)) OVER (Partition BY Deaths.Location ORDER BY Deaths.Location, Deaths.Date) AS RollingPeopleVaccinated
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON Deaths.Location = Vax.Location
	AND Deaths.Date = Vax.Date
WHERE Deaths.Continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population) *100 AS RollingPercentagePopVaccinated
FROM Pop_vs_Vax

/* TEMP TABLE*/

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date Datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vax.New_vaccinations
, SUM(CONVERT(int, Vax.New_Vaccinations)) OVER (Partition BY Deaths.Location ORDER BY Deaths.Location, Deaths.Date) AS RollingPeopleVaccinated
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON Deaths.Location = Vax.Location
	AND Deaths.Date = Vax.Date
WHERE Deaths.Continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS RollingPercentageVaccinated
FROM #PercentPopulationVaccinated

/* CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS */

CREATE View PercentPopulationVaccinated AS 
SELECT Deaths.Continent, Deaths.Location, Deaths.Date, Deaths.Population, Vax.New_vaccinations
, SUM(CONVERT(int, Vax.New_Vaccinations)) OVER (Partition BY Deaths.Location ORDER BY Deaths.Location, Deaths.Date) AS RollingPeopleVaccinated
FROM CovidDeaths AS Deaths
JOIN CovidVaccinations AS Vax
	ON Deaths.Location = Vax.Location
	AND Deaths.Date = Vax.Date
WHERE Deaths.Continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated