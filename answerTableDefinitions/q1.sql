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
    select DISTINCT election_id, party_id from election_winners;

DROP VIEW IF EXISTS country_names CASCADE;
CREATE VIEW country_names as
    select country.name as country, election_winners_unique.party_id, election_winners_unique.election_id
    from election_winners_unique join party
        on election_winners_unique.party_id = party.id
    join country
        on party.country_id = country.id;

DROP VIEW IF EXISTS century_20th CASCADE;
CREATE VIEW century_20th as
    select CAST('20' as VARCHAR(2)) as century, country_names.country, country_names.party_id, country_names.election_id
    from country_names join election
        on country_names.election_id = election.id
    where election.e_date >= '1901-01-01' and election.e_date < '2001-01-01';

DROP VIEW IF EXISTS century_21st CASCADE;
CREATE VIEW century_21st as
    select CAST('20' as VARCHAR(2)) as century, country_names.country, country_names.party_id, country_names.election_id
    from country_names join election
        on country_names.election_id = election.id
    where election.e_date >= '2001-01-01';

DROP VIEW IF EXISTS century_combined CASCADE;
CREATE VIEW century_combined as
    (select * from century_20th) UNION ALL (select * from century_21st);



-- the answer to the query
-- insert into q1
--   SELECT *
--   FROM election_winners;
