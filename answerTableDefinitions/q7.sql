SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
partyId INT,
partyFamily VARCHAR(50)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS parliamentary_elections CASCADE;
CREATE VIEW parliamentary_elections as
    select *
    from election
    where e_type = 'Parliamentary election';

DROP VIEW IF EXISTS parliamentary_election_winners CASCADE;
CREATE VIEW parliamentary_election_winners as
    select parliamentary_elections.id as election_id, cabinet_party.party_id
    from parliamentary_elections join cabinet
        on parliamentary_elections.id = cabinet.election_id
    join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party.pm = true;

DROP VIEW IF EXISTS parliamentary_election_winners_unique CASCADE;
CREATE VIEw parliamentary_election_winners_unique as
    select DISTINCT election_id, party_id from parliamentary_election_winners;

DROP VIEW IF EXISTS european_elections CASCADE;
CREATE VIEW european_elections as
  select id, country_id, previous_parliament_election_id, previous_ep_election_id
  from election
  where e_type = 'European Parliament';

DROP VIEW IF EXISTS european_parliament_countries CASCADE;
CREATE VIEW european_parliament_countries as
  select DISTINCT country_id
  from european_elections;

DROP VIEW IF EXISTS party_wins_after_first_european_election CASCADE;
create view party_wins_after_first_european_election as
  select election.id, party_id, european_elections.country_id,
  european_elections.previous_parliament_election_id, european_elections.previous_ep_election_id
  from parliamentary_election_winners_unique join election
    on parliamentary_election_winners_unique.election_id = election.id
  join european_elections
    on european_elections.previous_ep_election_id = election.previous_ep_election_id;

DROP VIEW IF EXISTS party_wins_before_first_european_election CASCADE;
create view party_wins_before_first_european_election as
  select election.id, party_id, european_elections.country_id,
  european_elections.previous_parliament_election_id, european_elections.previous_ep_election_id
  from parliamentary_election_winners_unique join election
    on parliamentary_election_winners_unique.election_id = election.id
  join european_elections
    on european_elections.country_id = election.country_id
    and european_elections.previous_ep_election_id IS NULL
    and election.previous_ep_election_id IS NULL
  where EXISTS (
    select *
    from european_parliament_countries
    where european_elections.country_id = european_parliament_countries.country_id
  );

DROP VIEW IF EXISTS parties_with_wins_before_after_european_election CASCADE;
CREATE VIEW parties_with_wins_before_after_european_election as
  select distinct id, party_id
  from (select id, party_id from party_wins_before_first_european_election) INTERSECT
  (select id, party_id from party_wins_after_first_european_election);

DROP VIEW IF EXISTS num_european_elections_per_country CASCADE;
CREATE VIEW num_european_elections_per_country as
  select country_id, count(country_id) as num_elections
  from european_elections
  group by county_id;

--DROP VIEW IF EXISTS party_wins_per_european_election CASCADE;
--CREATE VIEW party_wins_per_european_election as


-- the answer to the query
--insert into q7
