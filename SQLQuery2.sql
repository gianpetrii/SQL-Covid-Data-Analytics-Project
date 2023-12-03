/*
Primero guarde mis excel y voy a base de datos -> tasks -> import data
ahi elijo excel y destino es el ultimo que dice "provider" y luego selecciono la hoja del excel
cuidando que no se pisen los nombres y que la base de datos a la que importar es correcta
*/

SELECT location, date, total_cases, new_cases, total_deaths, population 
from CovidDeaths
order by 1,2



-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (cast(total_deaths) as int / cast(total_cases) as int) * 100 as DeathPercentage
from CovidDeaths
Where location like 'Argentina'
order by 1,2



-- Total Cases vs Population
-- What porcentage of the pop has covid
SELECT location, date, total_cases, population, (total_cases / population) * 100 as PercentagePopulationHadCovid
from CovidDeaths
Where location like 'Argentina'
order by 1,2



-- Countries with highest infection rates
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases / population) * 100 as PercentagePopulationInfected
from CovidDeaths
Group By location, population
order by PercentagePopulationInfected desc



-- Countries with highest death count per capita
SELECT location, MAX(total_deaths / population) * 100 as PercentagePopulationIDied
from CovidDeaths
where continent is not null		-- (con esto no me muestra continentes)
Group By location
order by PercentagePopulationIDied desc




-- Countries with highest death count
SELECT location, MAX(total_deaths) as HighestDeadCount
from CovidDeaths
where continent is not null		-- (con esto no me muestra continentes)
Group By location
order by HighestDeadCount desc



-- If we do it by continent
SELECT continent, MAX(total_deaths) as HighestDeadCount
from CovidDeaths
Group By continent
order by HighestDeadCount desc



-- global numbers
SELECT date, SUM(new_cases), SUM(new_deaths) 
from CovidDeaths
where continent is not null
Group by date
order by 1,2


SELECT date, SUM(new_cases) as newCases, SUM(new_deaths) as newDeaths,SUM(new_deaths)/SUM(new_cases) * 100 as InfectionPercentageForDay
from CovidDeaths
where continent is not null and new_cases <> 0
Group by date
order by 1,2


-- total population vs vaccionations
select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
from CovidDeaths as deaths
Join CovidVacc as vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null
order by 2,3



-- in argentina
select  deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
from CovidDeaths as deaths
Join CovidVacc as vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null
and deaths.location like 'Argentina'
order by 1,2



-- 
select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
 SUM(cast(vacc.new_vaccinations) as int) OVER (partition by deaths.location, deaths.date) as SummOffVaccPeople
 -- con el partititon reseteo el count
from CovidDeaths as deaths
Join CovidVacc as vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null
order by 2,3



-- create a cte to be able to use column just created
With PopVsVacc (
continent, location, date, population, new_vaccinations,SummOffVaccPeople
) as
(
select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
 SUM(cast(vacc.new_vaccinations) as int) OVER (partition by deaths.location, deaths.date) as SummOffVaccPeople
 -- con el partititon reseteo el count
from CovidDeaths as deaths
Join CovidVacc as vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null
)

Select *, (SummOffVaccPeople / population) * 100 as RollingVaccPeople
from PopVsVacc



-- another option is with temp_table
DROP TABLE IF exists #percentage_vacc_population
CREATE table #percentage_vacc_population
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
SummOffVaccPeople numeric
)


Insert into #percentage_vacc_population
select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
 SUM(cast(vacc.new_vaccinations) as int) OVER (partition by deaths.location, deaths.date) as SummOffVaccPeople
 -- con el partititon reseteo el count
from CovidDeaths as deaths
Join CovidVacc as vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null

Select *, (SummOffVaccPeople / population) * 100 as RollingVaccPeople
from #percentage_vacc_population




-- creating view for later visualization
CREATE VIEW #percentage_vacc_population
select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
 SUM(vacc.new_vaccinations)OVER (partition by deaths.location, deaths.date) as SummOffVaccPeople
 -- con el partititon reseteo el count
from CovidDeaths as deaths
Join CovidVacc as vacc
	On deaths.location = vacc.location
	and deaths.date = vacc.date
where deaths.continent is not null