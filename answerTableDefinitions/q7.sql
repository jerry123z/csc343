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
  select id, country_id, e_date, previous_parliament_election_id, previous_ep_election_id
  from election
  where e_type = 'European Parliament';

DROP VIEW IF EXISTS european_parliament_countries CASCADE;
CREATE VIEW european_parliament_countries as
  select DISTINCT country_id
  from european_elections;

DROP VIEW IF EXISTS party_wins_after_first_european_election CASCADE;
create view party_wins_after_first_european_election as
  select election.id, election.e_date, party_id, european_elections.country_id,
  european_elections.previous_parliament_election_id, european_elections.previous_ep_election_id
  from parliamentary_election_winners_unique join election
    on parliamentary_election_winners_unique.election_id = election.id
  join european_elections
    on european_elections.previous_ep_election_id = election.previous_ep_election_id;

DROP VIEW IF EXISTS party_wins_before_first_european_election CASCADE;
create view party_wins_before_first_european_election as
  select election.id, election.e_date, party_id, european_elections.country_id,
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

DROP VIEW IF EXISTS inters;
CREATE VIEW inters as
  (select distinct party_id from party_wins_before_first_european_election) INTERSECT
  (select distinct party_id from party_wins_after_first_european_election);

DROP VIEW IF EXISTS parties_with_wins_before_after_european_election CASCADE;
CREATE VIEW parties_with_wins_before_after_european_election as
  select party_wins_after_first_european_election.id,
  party_wins_after_first_european_election.e_date,
  party_wins_after_first_european_election.party_id,
  party_wins_after_first_european_election.country_id,
  party_wins_after_first_european_election.previous_parliament_election_id,
  party_wins_after_first_european_election.previous_ep_election_id
  from inters join party_wins_after_first_european_election
    on inters.party_id = party_wins_after_first_european_election.party_id;

DROP VIEW IF EXISTS parties_with_year_elected_after_first CASCADE;
CREATE VIEW parties_with_year_elected_after_first as
  select distinc extract (year from parties_with_wins_before_after_european_election.e_date) as year,
  parties_with_wins_before_after_european_election.party_id
  from parties_with_wins_before_after_european_election;

DROP VIEW IF EXISTS elections_with_dates CASCADE;
CREATE VIEW elections_with_dates as
  select distinct extract (year from e1.e_date) as curr_date, extract(year from e2.e_date)as prev_date
  from european_elections as e1 join european_elections as e2
  on e1.previous_ep_election_id = e2.id;

DROP VIEW IF EXISTS strong_parties CASCADE;
CREATE VIEW strong_parties as
  select party_id, count(party_id) as dist_elected
  from parties_with_year_elected_after_first
  where EXISTS(
    select *
    from elections_with_dates
    where prev_date <= parties_with_year_elected_after_first.year and curr_date> parties_with_year_elected_after_first.year
  )
  group by party_id;

DROP VIEW IF EXISTS num_eu_elections CASCADE;
CREATE VIEW num_eu_elections AS
  select count(curr_date) as goal
  from elections_with_dates;

DROP VIEW IF EXISTS final CASCADE;
CREATE VIEW final as
  select strong_parties.party_id, family
  from strong_parties join num_eu_elections
    on strong_parties.dist_elected = num_eu_elections.goal
  join party_family
    on strong_parties.party_id = party_family.party_id;
--DROP VIEW IF EXISTS party_wins_per_european_election CASCADE;
--CREATE VIEW party_wins_per_european_election as


-- the answer to the query
--insert into q7
