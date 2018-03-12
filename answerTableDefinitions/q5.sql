SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
electionId INT,
countryName VARCHAR(50),
winningParty VARCHAR(100),
closeRunnerUp VARCHAR(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
--DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS fixed_nulls;
CREATE VIEW fixed_nulls as
  select id, election_id, party_id, id as alliance_id, seats, votes
  from election_result
  where alliance_id is NULL;

DROP VIEW IF EXISTS election_result_no_null;
CREATE VIEW election_result_no_null as
  select id, election_id, party_id, alliance_id, seats, votes
  from election_result
  where alliance_id is not NULL;

DROP VIEW IF EXISTS election_results_better;
CREATE VIEW election_results_better as
  (select * from fixed_nulls) UNION (select * from election_result_no_null);

DROP VIEW IF EXISTS election_winners CASCADE;
CREATE VIEW election_winners as
    select parliamentary_elections.id as election_id, cabinet_party.party_id
    from elections join cabinet
        on parliamentary_elections.id = cabinet.election_id
    join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party.pm = true;

DROP VIEW IF EXISTS election_winners_unique CASCADE;
CREATE VIEw election_winners_unique as
    select DISTINCT election_id, party_id from election_winners;

DROP VIEW IF EXISTS election_winners_result CASCADE;
CREATE VIEw election_winners_result as
    select id, election_result.election_id, election_resutl.party_id, id as alliance_id, seats, votes
    from election_winners_unique join election_result
    on election_winners_unique.election_id = election_result.election_id
    and election_winners_unique.party_id = election_result.party_id;

DROP VIEW IF EXISTS election_winners_fixed_nulls;
CREATE VIEW election_winners_fixed_nulls as
  select id, election_id, party_id, id as alliance_id, seats, votes
  from election_winners_result
  where alliance_id is NULL;

DROP VIEW IF EXISTS election_winners_result_no_null;
CREATE VIEW election_winners_result_no_null as
  select id, election_id, party_id, alliance_id, seats, votes
  from election_winners_result
  where alliance_id is not NULL;

DROP VIEW IF EXISTS election_winners_results_better;
CREATE VIEW election_winners_results_better as
  (select * from election_winners_fixed_nulls) UNION (select * from election_winners_result_no_null);

DROP VIEW IF EXISTS election_winners_sum_votes;
CREATE VIEW election_winners_sum_votes;
    select election_id,  alliance_id, SUM(votes),
    from election_winners_results_better
    group by election_id, alliance_id;

DROP VIEW IF EXISTS alliances_sum_votes;
CREATE VIEW alliances_sum_votes as
    select election_id,  alliance_id, SUM(votes),
    from election_results_better
    group by election_id, alliance_id;

DROP VIEW IF EXISTS alliances_sum_votes_no_winners;
CREATE VIEW alliances_sum_votes_no_winners as
  (alliances_sum_votes) except (election_winners_sum_votes);

-- the answer to the query
--insert into q5
