Select *
From CovidDeaths
Where continent is not null
Order By 3, 4



-- Select data that I will be using

Select location, date, total_cases, new_cases, total_deaths, new_deaths, population
From CovidDeaths
where continent is not null
Order By location, date


-- Looking at Total Cases vs Total Deaths
-- I also checked to see if there were cases where the deaths were more than the cases but there weren't

--With CTE_Error AS (
--Select location, MAX(cast(total_cases as float)) as TotalCases, MAX(cast(total_deaths as float)) as TotalDeaths,
--CASE
--	When MAX(cast(total_cases as int)) < MAX(cast(total_deaths as int)) Then 'Error'
--	Else 'No Error'
--END as Accuracy
--From CovidDeaths
--Group By location
--)

--SELECT Accuracy, Count(Accuracy)
--From CTE_Error
--Group By Accuracy

-- DEATH COUNT

-- Death Count from Infected Population by Country

Select location, MAX(cast(total_cases as float)) as TotalCases, MAX(cast(total_deaths as float)) as TotalDeaths, (MAX(cast(total_deaths as float))/MAX(cast(total_cases as float))) * 100 as PercentageDeaths
From CovidDeaths
where continent is not null
Group By location
Order By TotalDeaths DESC


-- Death Count from Infected Population over time by Country

Select location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float)) * 100 as PercentageCases
From CovidDeaths
where continent is not null
Order by 1, 2





-- INFECTION COUNT

-- Looking at countries Infection Count compared to Population

Select location, MAX(cast(total_cases as float)) as TotalCases, MAX(population) as TotalPopulation, (MAX(cast(total_cases as float))/MAX(population)) * 100 AS PercentPopulationInfected
From CovidDeaths
where continent is not null
Group By location
Order By PercentPopulationInfected DESC


-- Looking at Coutnries Infection Count over Population over time

Select location, date, population, total_cases, (cast(total_cases as float)/population) * 100 as PercentPopulationInfected
From CovidDeaths
where continent is not null
Order by 1, 2





-- BREAK DOWN BY CONTINENT

-- Death Count by Continet

Select location as ContinentLocation, MAX(cast(total_cases as float)) as TotalCases, MAX(cast(total_deaths as float)) as TotalDeaths, (MAX(cast(total_deaths as float))/MAX(cast(total_cases as float))) * 100 as PercentageDeaths
From CovidDeaths
where continent is null and location in ('North America', 'South America', 'Europe', 'Africa', 'Asia', 'Oceania')
Group By location
Order By TotalDeaths

-- Infection Count by Continent

Select location as ContinentLocation, MAX(population) as Population, MAX(cast(total_cases as float)) as TotalCases, (MAX(cast(total_cases as float))/MAX(population)) * 100 as ContinentPercentageInfected
From CovidDeaths
where continent is null and location in ('North America', 'South America', 'Europe', 'Africa', 'Asia', 'Oceania')
Group By location
Order By ContinentPercentageInfected DESC


-- GLOBAL NUMBERS

Select --date,
SUM(new_cases) as GlobalCases, SUM(new_deaths) as GlobalDeaths, (SUM(new_deaths)/NULLIF(SUM(new_cases), 0)) * 100 as PercentageDeath
From CovidDeaths
where continent is not null
--Group By date
--Order by date


-- Total Population vs Vaccination

Select dea.continent, dea.location, MAX(population) as population, MAX(cast(total_vaccinations as float)) as TotalPeopleVaccinated
From CovidDeaths dea
Join CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
Group By dea.continent, dea.location
Order By dea.continent, dea.location


-- New Vaccinations per day

Select dea.continent, dea.location, dea.date, population, new_vaccinations
From CovidDeaths dea
Join CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
Order By dea.continent, dea.location, dea.date


-- Rolling count of vaccinations per day

Select dea.continent, dea.location, dea.date, population, new_vaccinations
, SUM(cast(new_vaccinations as float)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingVaccinationCount
From CovidDeaths dea
Join CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
Order By dea.continent, dea.location, dea.date


-- Using rolling count and a CTE to get percent of total people vaccinated per country per day

With CTE_PercentVaccinated as (
Select dea.continent, dea.location, dea.date, population, new_vaccinations
, SUM(cast(new_vaccinations as float)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingVaccinationCount
From CovidDeaths dea
Join CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--Order By dea.continent, dea.location, dea.date
)

Select *, (RollingVaccinationCount/population) * 100 as PercentVaccinated
From CTE_PercentVaccinated


-- Temp Table

Drop Table if exists #PercentVaccinated
Create Table #PercentVaccinated (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population float,
New_vaccinations float,
RollingVaccinationCount float
)

Insert Into #PercentVaccinated
Select dea.continent, dea.location, dea.date, population, new_vaccinations
, SUM(cast(new_vaccinations as float)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingVaccinationCount
From CovidDeaths dea
Join CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--Order By dea.continent, dea.location, dea.date

Select *, RollingVaccinationCount/Population * 100 as PercentVaccinated
From #PercentVaccinated


-- CREATING VIEWS FOR LATER VISUALISATIONS

-- Total Vaccinations per continent and country over population

Create View TotPopVaccinated as
Select dea.continent, dea.location, MAX(population) as population, MAX(cast(total_vaccinations as float)) as TotalPeopleVaccinated
From CovidDeaths dea
Join CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
Group By dea.continent, dea.location
--Order By dea.continent, dea.location

-- Rolling vaccination view per country per day

Create View RollingVaccinated as
Select dea.continent, dea.location, dea.date, population, new_vaccinations
, SUM(cast(new_vaccinations as float)) OVER (Partition By dea.location Order By dea.location, dea.date) as RollingVaccinationCount
From CovidDeaths dea
Join CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
Where dea.continent is not null
--Order By dea.continent, dea.location, dea.date


-- Countries Infection Count compared to Population

Create View CountriesPopInfected as
Select location, MAX(cast(total_cases as float)) as TotalCases, MAX(population) as TotalPopulation, (MAX(cast(total_cases as float))/MAX(population)) * 100 AS PercentPopulationInfected
From CovidDeaths
where continent is not null
Group By location
--Order By PercentPopulationInfected DESC


-- Continent Infection Count compared to Population

Create View ContinentPopInfected as
Select location as ContinentLocation, MAX(population) as Population, MAX(cast(total_cases as float)) as TotalCases, (MAX(cast(total_cases as float))/MAX(population)) * 100 as ContinentPercentageInfected
From CovidDeaths
where continent is null and location in ('North America', 'South America', 'Europe', 'Africa', 'Asia', 'Oceania')
Group By location
--Order By ContinentPercentageInfected DESC


-- Countries Deaths Compared to Infections

Create View CountriesInfDeaths as
Select location, MAX(cast(total_cases as float)) as TotalCases, MAX(cast(total_deaths as float)) as TotalDeaths, (MAX(cast(total_deaths as float))/MAX(cast(total_cases as float))) * 100 as PercentageDeaths
From CovidDeaths
where continent is not null
Group By location
--Order By TotalDeaths DESC


-- Continent Deaths Compared to Infections

Create View ContinentInfDeaths as
Select location as ContinentLocation, MAX(cast(total_cases as float)) as TotalCases, MAX(cast(total_deaths as float)) as TotalDeaths, (MAX(cast(total_deaths as float))/MAX(cast(total_cases as float))) * 100 as PercentageDeaths
From CovidDeaths
where continent is null and location in ('North America', 'South America', 'Europe', 'Africa', 'Asia', 'Oceania')
Group By location
--Order By TotalDeaths


