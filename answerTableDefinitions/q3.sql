SET SEARCH_PATH TO parlgov;
drop table if exists q3 cascade;

-- You must not change this table definition.

create table q3(
country VARCHAR(50),
num_dissolutions INT,
most_recent_dissolution DATE,
num_on_cycle INT,
most_recent_on_cycle DATE
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS parliamentary_elections CASCADE;
CREATE VIEW parliamentary_elections as
  select id, country_id, e_date, previous_parliament_election_id
  FROM election
  where e_type = 'Parliamentary election';

DROP VIEW IF EXISTS country_cycle CASCADE;
CREATE VIEW country_cycle as
  select id, name, election_cycle
  from country;

DROP VIEW IF EXISTS both_e_dates CASCADE;
CREATE VIEW both_e_dates as
  select p1.id, p1.country_id, p1.e_date as curr_e_date, p1.previous_parliament_election_id,
  p2.e_date as prev_e_date, country_cycle.name, country_cycle.election_cycle
  from parliamentary_elections as p1 join parliamentary_elections as p2
  on p1.previous_parliament_election_id = p2.id
  join country_cycle
   on country_cycle.id = p1.country_id;

DROP VIEW IF EXISTS under_dissolutions CASCADE;
CREATE VIEW under_dissolutions as
  select *
  from both_e_dates
  where ((curr_e_date - prev_e_date) < (365 * election_cycle));

DROP VIEW IF EXISTS over_dissolutions CASCADE;
CREATE VIEW over_dissolutions as
  select *
  from both_e_dates
  where ((curr_e_date - prev_e_date) > (365 * (election_cycle + 1)));

DROP VIEW IF EXISTS dissolutions CASCADE;
CREATE VIEW dissolutions as
  (select * from under_dissolutions) UNION (select * from over_dissolutions);

DROP VIEW IF EXISTS non_dissolutions CASCADE;
CREATE VIEW non_dissolutions as
    (select * from both_e_dates) EXCEPT (select * from dissolutions);

DROP VIEW IF EXISTS count_dissolutions CASCADE;
CREATE VIEW count_dissolutions as
  select DISTINCT name, count(id) as num_dissolutions
  from dissolutions
  GROUP BY name;

DROP VIEW IF EXISTS max_dissolutions CASCADE;
CREATE VIEW max_dissolutions as
  select DISTINCT name, max(curr_e_date) as most_recent_dissolution
  from dissolutions
  GROUP BY name;

DROP VIEW IF EXISTS count_non_dissolutions CASCADE;
CREATE VIEW count_non_dissolutions as
  select DISTINCT name, count(id) as num_on_cycle
  from non_dissolutions
  GROUP BY name;

DROP VIEW IF EXISTS max_non_dissolutions CASCADE;
CREATE VIEW max_non_dissolutions as
  select DISTINCT name, max(curr_e_date) as most_recent_on_cycle
  from non_dissolutions
  GROUP BY name;

DROP VIEW IF EXISTS final CASCADE;
CREATE VIEW final as
  select dissolutions.name as country, count_dissolutions as num_dissolutions,
  max_dissolutions as most_recent_dissolution, count_non_dissolutions as num_on_cycle,
  max_dissolutions as most_recent_on_cycle
  from max_dissolutions join count_dissolutions on max_dissolutions.name = count_dissolutions.name
  join count_non_dissolutions on max_dissolutions.name = count_non_dissolutions.name
  join max_non_dissolutions on max_dissolutions.name = max_non_dissolutions.name;

-- the answer to the query
-- insert into q3
