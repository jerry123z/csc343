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
DROP VIEW IF EXISTS intermediate_step CASCADE;

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

DROP VIEW IF EXISTS country_names CASCADE;
CREATE VIEW country_names as
    select country.name as country, election_winners.party_id, election_winners.election_id
    from election_winners join party
        on election_winners.party_id = party.id
    join country
        on party.country_id = country.id;

DROP VIEW IF EXISTS century_20th CASCADE;
CREATE VIEW century_20th as
    select CAST('20' as VARCHAR(2)) as century, country_names.country, country_names.party_id, country_names.election_id
    from country_names join election
        on country_names.election_id = election.id
    where election.e_date >= '1901-01-01' and election.e_date < '2001-01-01';

-- TODO: complete for 21st century
DROP VIEW IF EXISTS century_21st CASCADE;
CREATE VIEW century_21st as
    select CAST('21' as VARCHAR(2)) as century, country_names.country, country_names.party_id, country_names.election_id
    from country_names join election
        on country_names.election_id = election.id
    where election.e_date >= '2001-01-01' and election.e_date < '2101-01-01';

DROP VIEW IF EXISTS winners_result_id CASCADE;
CREATE VIEW winners_result_id as
    select century_20th.century, century_20th.country, century_20th.party_id, century_20th.election_id, election_result.alliance_id, election_result.id as id
    from century_20th join election_result using(election_id, party_id);

DROP VIEW IF EXISTS head_parties CASCADE;
CREATE VIEW head_parties as
    select winners_result_id.century, winners_result_id.country, winners_result_id.party_id, winners_result_id.election_id, winners_result_id.id as alliance_id, winners_result_id.id
    from winners_result_id
    where alliance_id is NULL;

DROP VIEW IF EXISTS alliances CASCADE;
CREATE VIEW alliances as
    ((select century, country, party_id, election_id, alliance_id, id
    from winners_result_id
    where alliance_id is not NULL)

    UNION ALL

    (select century, country, party_id, election_id, alliance_id, id
    from head_parties));

DROP VIEW IF EXISTS stats_per_alliance CASCADE;
CREATE VIEW stats_per_alliance as
    select alliance_id, avg(left_right) as left_right, avg(state_market) as state_market, avg(liberty_authority) as liberty_authority
    from alliances join party_position using(party_id)
    group by alliance_id;

DROP VIEW IF EXISTS alliance_stats_with_details CASCADE;
CREATE VIEW alliance_stats_with_details as
    select country, avg(left_right) as left_right, avg(state_market) as state_market, avg(liberty_authority) as liberty_authority
    from alliances join stats_per_alliance using(alliance_id)
    group by country;


-- the answer to the query
--insert into q1
--   SELECT *
--   FROM election_winners;
