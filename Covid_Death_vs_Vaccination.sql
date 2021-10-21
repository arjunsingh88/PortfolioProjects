/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Table Covid Deaths
SELECT *
FROM PortfolioProject..CovidDeaths
order by 3,4

-- Table Covid Vaccinations
SELECT *
FROM PortfolioProject..CovidVaccinations
order by 3,4


--Select Data that we are ging to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
Where continent is not null 
ORDER BY 1,2


-- Looking at Total Cases V/s Total Deaths
-- Shows likelihood of dying when tested positive for COVID & based on what country we are, in this case we are looking in INDIA
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%india%'
and continent is not null 
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
-- Note: Static population number is not a good stats, as population increases every second
SELECT location, date,  population, total_cases, (total_cases/population)*100 as Percentage_Population_Infection_Rate
FROM PortfolioProject..CovidDeaths
WHERE location like '%india%'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population
-- Note: Static population number is not a good stats
SELECT location, population, MAX(total_cases) as Overall_Case_count, MAX((total_cases/population)*100) as Percentage_Population_Infection_Rate
FROM PortfolioProject..CovidDeaths
group by location, population 
order by Percentage_Population_Infection_Rate DESC


-- Countries with Highest Death Count per Population
-- Note: A small problem with datatype of population column i.e. nvarchar, so we need to CAST it as integer
SELECT location, MAX(CAST(total_deaths as int)) as Total_Death_count
FROM PortfolioProject..CovidDeaths 
WHERE continent is not NULL -- this condition is because we have continent count in data as well
group by location 
order by Total_Death_count DESC 


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population, 
-- Used GROUP BY to view by location
SELECT location, MAX(CAST(total_deaths as int)) as Total_Death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is NULL -- this condition is because we have continent count in data as well
group by location 
order by Total_Death_count DESC 


-- Global Numbers (Across the world, every day)
-- This number present the evolution of 2 key features every day i.e. Total Cases & Total Deaths
SELECT date, SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths as INT)) as Total_Deaths, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as Death_Percentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%india%'
WHERE continent is not null 
GROUP BY date
ORDER BY 1,2


-- Monthly Global numbers i.e. total new cases, total new deaths, Death percentage every month
-- GIves an insight into pandemic and the trends, easy to detect Covid waves
SELECT YEAR(date) as YYYY, MONTH(date) as MM, SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths as INT)) as Total_Deaths, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 as Death_Percentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%india%'
WHERE continent is not null 
GROUP BY YEAR(date), MONTH(date)
ORDER BY 1,2

-- Breaking it by Month and Year to see the the evolution of Global Numbers i.e. total cases & total deaths at end of every month
SELECT YEAR(date) as YYYY, MONTH(date) as MM, MAX(total_cases) as Total_Cases, MAX(CAST(total_deaths as INT)) as Total_Deaths, (MAX(CAST(new_deaths as INT))/MAX(new_cases))*100 as Death_Percentage
FROM PortfolioProject..CovidDeaths
-- WHERE location like '%india%'
WHERE continent is not null 
GROUP BY YEAR(date), MONTH(date)
ORDER BY 1,2


-- Lets have a look at some important data from Vaccination data
SELECT location,continent, date, total_tests, new_tests
FROM PortfolioProject..CovidVaccinations
Where continent is not null 
ORDER BY 1,2


-- Joining Vaccination and Deat table to extract more insights
SELECT *
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date


-- Looking at Total Vaccinations v/s World population
-- We compute rolling count of new cases  
-- Rolling COUNT, so we partition by countries because we want to see numbers by countries and then order them based on the country and the date
SELECT dea.continent, dea.location, dea.date, dea.population , vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Now to have look at the vaccinated population against the total population
-- Three strategies to do this
-- 1. Use CTE
WITH PopVsVac (Continent, Location,  Date, Population, New_Vaccinations, Rolling_PeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population , vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
where dea.continent is not null 
-- order by 2,3
)
SELECT *, (Rolling_PeopleVaccinated/Population)*100 
FROM PopVsVac
ORDER BY 2,3


-- 2. USE the TEMP table instead of CTE, especially if we want to alter it or do some other computationa and easy to maintain
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),  
Date datetime, 
Population numeric,
New_Vaccinations numeric, 
Rolling_People_Vaccinated numeric(12, 0)
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population , vac.new_vaccinations, 
SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
--where dea.continent is not null 
-- order by 2,3
SELECT *, (Rolling_People_Vaccinated/Population)*100 
FROM #PercentPopulationVaccinated


-- 3. Creating View to store data for later visualizations
-- Real Asset especially when we want to visualize itin Data Visualization tools
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population , vac.new_vaccinations, 
SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION by dea.location ORDER by dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
where dea.continent is NOT NULL

SELECT *, (Rolling_People_Vaccinated/population)*100 
FROM PercentPopulationVaccinated 
ORDER BY 2,3
