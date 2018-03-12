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
DROP VIEW IF EXISTS fixed_nulls CASCADE;
CREATE VIEW fixed_nulls as
  select id, election_id, party_id, id as alliance_id, seats, votes
  from election_result
  where alliance_id is NULL;

DROP VIEW IF EXISTS election_result_no_null CASCADE;
CREATE VIEW election_result_no_null as
  select id, election_id, party_id, alliance_id, seats, votes
  from election_result
  where alliance_id is not NULL;

DROP VIEW IF EXISTS election_results_better CASCADE;
CREATE VIEW election_results_better as
  (select * from fixed_nulls) UNION (select * from election_result_no_null);

DROP VIEW IF EXISTS election_winners CASCADE;
CREATE VIEW election_winners as
    select election.id as election_id, cabinet_party.party_id
    from election join cabinet
        on election.id = cabinet.election_id
    join cabinet_party
        on cabinet.id = cabinet_party.cabinet_id
    where cabinet_party.pm = true;

DROP VIEW IF EXISTS election_winners_unique CASCADE;
CREATE VIEw election_winners_unique as
    select DISTINCT election_id, party_id from election_winners;

DROP VIEW IF EXISTS election_winners_result CASCADE;
CREATE VIEw election_winners_result as
    select id, election_result.election_id, election_result.party_id, election_result.alliance_id, seats, votes
    from election_winners_unique join election_result
    on election_winners_unique.election_id = election_result.election_id
    and election_winners_unique.party_id = election_result.party_id;

DROP VIEW IF EXISTS election_winners_fixed_nulls CASCADE;
CREATE VIEW election_winners_fixed_nulls as
  select id, election_id, party_id, id as alliance_id, seats, votes
  from election_winners_result
  where alliance_id is NULL;

DROP VIEW IF EXISTS election_winners_result_no_null CASCADE;
CREATE VIEW election_winners_result_no_null as
  select id, election_id, party_id, alliance_id, seats, votes
  from election_winners_result
  where alliance_id is not NULL;

DROP VIEW IF EXISTS election_winners_results_better CASCADE;
CREATE VIEW election_winners_results_better as
  (select * from election_winners_fixed_nulls) UNION (select * from election_winners_result_no_null);

DROP VIEW IF EXISTS election_winners_sum_votes CASCADE;
CREATE VIEW election_winners_sum_votes as
    select election_id,  alliance_id, SUM(votes) as votes
    from election_winners_results_better
    group by election_id, alliance_id;

DROP VIEW IF EXISTS alliances_sum_votes CASCADE;
CREATE VIEW alliances_sum_votes as
    select election_id,  alliance_id, SUM(votes) as votes
    from election_results_better
    group by election_id, alliance_id;

DROP VIEW IF EXISTS alliances_sum_votes_no_winners CASCADE;
CREATE VIEW alliances_sum_votes_no_winners as
  (select * from alliances_sum_votes) except (select * from election_winners_sum_votes);

DROP VIEW IF EXISTS alliances_join_winners CASCADE;
CREATE VIEW alliances_join_winners as
  select election_winners_sum_votes.election_id,
  election_winners_sum_votes.alliance_id as winner_id,
  election_winners_sum_votes.votes as winner_votes,
  alliances_sum_votes_no_winners.alliance_id as opp_id,
  alliances_sum_votes_no_winners.votes as opp_votes
  from election_winners_sum_votes join alliances_sum_votes_no_winners
    on alliances_sum_votes_no_winners.election_id = election_winners_sum_votes.election_id;

DROP VIEW IF EXISTS close_calls CASCADE;
CREATE VIEw close_calls as
  select election_id as electionID, winner_id, opp_id
  from alliances_join_winners
  where opp_votes/winner_votes < 0.1;

DROP VIEW IF EXISTS close_calls_winner CASCADE;
CREATE VIEW close_calls_winner as
  select electionID, country_id, name as winningParty, opp_id
  from close_calls join party
  on winner_id = id;

DROP VIEW IF EXISTS close_calls_opp CASCADE;
CREATE VIEW close_calls_opp as
  select electionID, party.country_id, winningParty, name as closeRunnerUp
  from close_calls_winner join party
  on opp_id = id;

DROP VIEW IF EXISTS close_calls_country CASCADE;
CREATE VIEW close_calls_country as
  select electionID, name, winningParty, closeRunnerUp
  from close_calls_opp join country
  on country_id = id;
-- the answer to the query
--insert into q5
