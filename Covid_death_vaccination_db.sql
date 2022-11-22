Select location, date, total_cases, new_cases, total_deaths, population 
from Covid..CovidDeaths
-- We dont need continent wise data and removed them by seeing in actual table that 
--the country column with continent name don't have anything in corrosponding Contintnt Column Continent
Where Continent is not null
Order by 1,2

-- looking at total cases VS total deaths
-- shows chances of dying in India
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'Death %'
from Covid..CovidDeaths
Where Continent is not null and location = 'India'
Order by 1,2

-- looking at total cases VS population
-- shows what % population of India got covid
Select location, date, total_cases, population, (total_cases/population)*100 as PercentInfectedPopulation
from Covid..CovidDeaths
Where Continent is not null
--Where location = 'India'
Order by 1,2

-- MAX INFECTED POPULATION
Select location, Max(total_cases) as MaxInfectedCount, population, Max(total_cases/population)*100 as PercentInfectedPopulation
from Covid..CovidDeaths
Where Continent is not null
--Where location = 'India' 
Group by location, population
Order by PercentInfectedPopulation DESC


-- TOTAL PEOPLE DIED IN PANDEMIC
-- cast is used to convert data type acc. to own specific needs
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
from Covid..CovidDeaths
-- remember total_deaths column is cummulative sum of new_deaths column (from actual table),
-- i.e. Max(total_deaths) = Sum(new_deaths) 
-- We dont need continent wise data and removed them by seeing in actual table that 
--the country column with continent name don't have anything in corrosponding Contintnt Column Continent
Where Continent is not null
--Where location = 'India'
Group by location
Order by TotalDeathCount DESC

-- LETS BREAK DOWN THINGS INTO CONTINENTS ACC. TO DEATH RATES
Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from Covid..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount DESC

-- GLOBAL NUMBERS
Select Sum(cast(new_deaths as int)) as TotalDeathCount, Sum(new_cases) as TotalCasesCount, Sum(cast(new_deaths as int))/Sum(new_cases)*100 as PercentGlobalCount
from Covid..CovidDeaths
Where continent is not null
--Group by continent
Order by 1,2

--LOOKING AT TOTAL POPULATION VS VACCINATION ***ADVANCED***
--here if we write only date and not dea.date then it gives error bcuz 
--date column is in both tables we are joining, so we need to specify for which table we want to select the column
--we can write population as well as dea,population bcuz population column is only in CovidDeaths table  :)
Select dea.date, dea.continent, dea.location, population, vcc.new_vaccinations, 
Sum(Convert(int, vcc.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) as people_vaccinated
--,(people_vaccinated/ population)*100 this gives error as we can't use column that we just created(people_vaccinated),So CTE is used.
-- Sums new_vaccination for specific country and then restarts count for new country(partially)
-- After partition Order by is important to get Cummulative Sum of the new_vaccination.......otherwise its giving total sum in every cell 
from Covid..CovidDeaths dea
Join Covid..CovidVaccinations vcc 
On dea.location = vcc.location And dea.date = vcc.date
--similarly if we write only continent in WHERE statement it shows error......we need to br specific
Where dea.continent is not null 
Order by 3,1
-- (first orders location column) and (then orders date column given the location column) 


--WITH CTE (Common Table Expression)  NOTE SYNTAX...!!
-- CTE is a temporary(one-time)named result set that we can reference within a select, insert, update, delete, create view, merge statements
-- each CTE is like a named query that is stored in a virtual table (CTE) to be referenced later in a main query. 
With pop_vs_vacc (date, continent, location, population, new_vaccination, people_vaccinated)
As
(
Select dea.date, dea.continent, dea.location, population, vcc.new_vaccinations, 
Sum(Convert(int, vcc.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) as people_vaccinated
from Covid..CovidDeaths dea
Join Covid..CovidVaccinations vcc 
On dea.location = vcc.location And dea.date = vcc.date
Where dea.continent is not null 
--Order by 3,1
)

--CTE referenced in the MAIN QUERY
Select *, (people_vaccinated/ population)*100  as percent_people_vaccinated
from pop_vs_vacc


-- TEMP Table
-- Use Drop Table if exists statement if you want to edit the query
Drop Table if exists #population_vacciated
Create Table #population_vacciated
(
date datetime,
continent nvarchar(255),
location nvarchar(255),
population float,
new_vaccinations numeric,
people_vaccinated numeric
)
Insert into #population_vacciated
Select dea.date, dea.continent, dea.location, population, vcc.new_vaccinations, 
Sum(Convert(int, vcc.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) as people_vaccinated
from Covid..CovidDeaths dea
Join Covid..CovidVaccinations vcc 
On dea.location = vcc.location And dea.date = vcc.date
--Where dea.continent is not null 
--Order by 3,1


Select *, (people_vaccinated/ population)*100 as percent_people_vaccinated
from #population_vacciated


-- CREATE VIEW FOR LATER VISUALISATIONS

Create view population_vacciated
As
Select dea.date, dea.continent, dea.location, population, vcc.new_vaccinations, 
Sum(Convert(int, vcc.new_vaccinations)) Over (Partition by dea.location Order by dea.location, dea.date) as people_vaccinated
from Covid..CovidDeaths dea
Join Covid..CovidVaccinations vcc 
On dea.location = vcc.location And dea.date = vcc.date
Where dea.continent is not null 
--Order by 3,1

Select * From population_vacciated

-- By Abhishek Sharma :)
