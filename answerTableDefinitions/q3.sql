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
DROP VIEW IF EXISTS parlamentary_elections CASCADE;
CREATE VIEW parlamentary_elections as
  select id, country_id, e_date, previous_parliament_election_id
  FROM election
  where election_type = 'Parliamentary election';

DROP VIEW IF EXISTS country_cycle CASCADE;
CREATE VIEW country_cycle as
  select id, name, election_cycle
  from country;

DROP VIEW IF EXISTS both_e_dates CASCADE;
CREATE VIEW both_e_dates as
  select p1.id, p1.country_id, p1.e_date, p1.previous_parliament_election_id,
  p2.edate, country_cycle.name, country_cycle.election_cycle
  from parlamentary_elections as p1 join parlamentary_elections as p2, country_cycle
  where p1.previous_parliament_election_id = p2.id and country_cycle.id = p1.country_id;

-- the answer to the query
insert into q3
