SELECT *
FROM portfolio_covid..covid_deaths
WHERE continent != ''
ORDER BY 3, 4

SELECT *
FROM portfolio_covid..covid_vaccinations
WHERE continent != ''
ORDER BY 3, 4

SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM portfolio_covid..covid_deaths
ORDER BY 1, 2

-- Total Cases vs Total Deaths
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases*100) as death_percentage
FROM portfolio_covid..covid_deaths
WHERE location = 'Indonesia'
ORDER BY 1, 2

-- Total Cases vs Population
SELECT
	location,
	date,
	population,
	total_cases,
	(total_cases/population*100) as case_percentage
FROM portfolio_covid..covid_deaths
WHERE
	location = 'Indonesia'
	AND total_cases IS NOT NULL
ORDER BY 1, 2

-- Countries with Highest Infection Rate
SELECT
	location,
	population,
	MAX(total_cases) as highest_case_count,
	(MAX(total_cases)/population*100) as highest_case_percentage
FROM portfolio_covid..covid_deaths
WHERE continent != ''
GROUP BY location, population
ORDER BY highest_case_percentage DESC

-- Countries with Highest Death Count
SELECT
	location,
	MAX(CAST(total_deaths as INT)) as total_death_count
FROM portfolio_covid..covid_deaths
WHERE continent != ''
GROUP BY location
ORDER BY total_death_count DESC

-- Continents with Highest Death Count
SELECT
	location,
	MAX(CAST(total_deaths as INT)) as total_death_count
FROM portfolio_covid..covid_deaths
WHERE
	continent = ''
	AND location NOT LIKE '%income%'
	AND location NOT LIKE '%union%'
	AND location != 'World'
GROUP BY location
ORDER BY total_death_count DESC

-- Global Numbers (Death Rate)
SELECT
	SUM(new_cases) as total_case,
	SUM(new_deaths) as total_death,
	(SUM(new_deaths)/SUM(new_cases)*100) as death_rate
FROM portfolio_covid..covid_deaths
WHERE continent != ''

-- Total Population vs Vaccinations
-- Using Temp Table
--CREATE TABLE pop_vs_vac (
--	continent NVARCHAR(255),
--	location NVARCHAR(255),
--	date DATETIME,
--	population NUMERIC,
--	new_vaccinations  NUMERIC,
--	rolling_people_vaccinated  NUMERIC
--)

--INSERT INTO pop_vs_vac
--SELECT
--	dea.continent,
--	dea.location,
--	dea.date,
--	dea.population,
--	vac.new_vaccinations,
--	SUM(CAST(vac.new_vaccinations as FLOAT))
--		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
--		as rolling_people_vaccinated
--FROM portfolio_covid..covid_deaths dea
--JOIN portfolio_covid..covid_vaccinations vac
--	ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE
--	vac.new_vaccinations != ''
--	AND dea.continent != ''
--ORDER BY 2, 3

--DROP TABLE IF EXISTS pop_vs_vac

-- Total Population vs Vaccinations
-- Using CTE
WITH pop_vs_vac (
	continent,
	location,
	date,
	population,
	new_vaccinations,
	rolling_people_vaccinated
) as (
	SELECT
		dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as FLOAT))
			OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
			as rolling_people_vaccinated
	FROM portfolio_covid..covid_deaths dea
	JOIN portfolio_covid..covid_vaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE
		vac.new_vaccinations != ''
		AND dea.continent != ''
) SELECT
	*,
	(rolling_people_vaccinated/population*100) as vaccination_rate
FROM pop_vs_vac
ORDER BY location, date

-- Creating View
CREATE VIEW percent_population_vaccinated as
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as FLOAT))
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
		as rolling_people_vaccinated
FROM portfolio_covid..covid_deaths dea
JOIN portfolio_covid..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
	vac.new_vaccinations != ''
	AND dea.continent != ''

SELECT * FROM percent_population_vaccinated ORDER BY 2, 3
