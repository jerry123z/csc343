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

DROP VIEW IF EXISTS dissolutions CASCADE;
CREATE VIEW dissolutions as
  select *
  from both_e_dates
  where (curr_e_date - prev_e_date)< (365 * election_cycle) or (curr_e_date - prev_e_date)< (365 * (election_cycle + 1));


-- the answer to the query
-- insert into q3
