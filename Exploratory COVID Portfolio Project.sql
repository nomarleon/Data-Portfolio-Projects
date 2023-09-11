Metrics:

Data Range Analysis:

Metric: Time Period Analyzed
Explanation: This metric helps us understand the timeframe of our data analysis.
Calculation: Determine the earliest and latest dates available in the CovidDeaths and CovidVaccinations tables to establish the time range of your data.

COVID Impact in the United States:

Metric: Likelihood and Population Infected
Explanation: This metric focuses on the impact of COVID-19 in the United States.
Calculation: Calculate the likelihood of dying if contracting COVID-19 in the United States and the percentage of the population that has been infected with COVID-19.

Code:

--Retrieve the earliest and latest date available in the CovidDeaths and CovidVaccinations table

SELECT MIN(date) AS Earlier
FROM CovidDeaths

SELECT Max(date) AS Later
FROM CovidDeaths

SELECT MIN(date) AS Earlier
FROM CovidVaccinations

SELECT Max(date) AS Later
FROM CovidVaccinations


--Retrieve all data from the CovidDeaths table, filtering out any rows where the continent is null, and ordering the results by columns 3 and 4

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--Retrieve specific columns from the CovidDeaths table that will be used in the analysis, ordered by columns 1 and 2

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2


--Calculate the likelihood of dying if you contract COVID in the United States by retrieving the total cases, total deaths, and death percentage for the United States from the CovidDeaths table

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE Location like '%states%'
AND continent IS NOT NULL
ORDER BY 1,2


--Calculate the percentage of the population that has been infected with COVID in the United States by retrieving the population, total cases, and percentage of population infected from the CovidDeaths table

SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2


--Retrieve the highest infection count and percentage of population infected for each location in the CovidDeaths table, ordered by the percentage of population infected in descending order

SELECT Location,Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE Location like '%states%'
GROUP BY location,population 
ORDER BY PercentPopulationInfected DESC

--Retrieve the total death count for each location in the CovidDeaths table, ordered by the total death count in descending order

SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotaDeathCount
FROM CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotaDeathCount DESC


--Retrieve the total death count for each continent in the CovidDeaths table, ordered by the total death count in descending order

SELECT continent, MAX(cast(total_deaths AS INT)) AS TotaDeathCount
FROM CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotaDeathCount DESC


--Retrieve the total cases, total deaths, and death percentage for each date in the CovidDeaths table, ordered by date

SELECT date, SUM(new_cases) AS total_cases, 
			 SUM(cast(new_deaths AS INT)) AS total_deaths, 
			 SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY date ORDER BY 1,2 


--Retrieve the total cases, total deaths, and death percentage for all dates in the CovidDeaths table

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY 1,2



--Retrieve the population, new vaccinations, and rolling people vaccinated for each location and date in the CovidDeaths and CovidVaccinations tables, ordered by location and date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--Use a Common Table Expression (CTE) to simplify the query from point 11 and add a calculated column for the percentage of the population vaccinated

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


--Use a temporary table to store the data from point 12 and retrieve it later, adding the calculated column for the percentage of the population vaccinated

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


--Create a view to store the data from point 12 for later visualization

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
