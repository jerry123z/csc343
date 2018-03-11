SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
century VARCHAR(2),
country VARCHAR(50),
left_right REAL,
state_market REAL,
liberty_authority REAL
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
-- DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS parliamentary_elections CASCADE;
CREATE VIEW parliamentary_elections as
    select *
    from election
    where e_type = 'Parliamentary election';


DROP VIEW IF EXISTS election_winners CASCADE;
CREATE VIEW election_winners as
    select parliamentary_elections.id as election_id, cabinet_party.party_id
    from parliamentary_elections join cabinet
        on parliamentary_elections.id = cabinet.election_id
    join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party.pm = true;

DROP VIEW IF EXISTS election_winners_unique CASCADE;
CREATE VIEw election_winners_unique as
    select distict election_id, party_id from election_winners;

DROP VIEW IF EXISTS country_names CASCADE;
CREATE VIEW country_names as
    select country.name as country, election_winners_unique.party_id, election_winners.election_id
    from election_winners join election_winners_unique
        on election_winners_unique.party_id = party.id;

-- the answer to the query
-- insert into q1
--   SELECT *
--   FROM election_winners;
