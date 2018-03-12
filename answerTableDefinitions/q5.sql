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
  from relection_result
  where alliance_id is NULL;

DROP VIEW IF EXISTS election_result_no_null;
CREATE VIEW election_result_no_null as
  select id, election_id, party_id, alliance_id, seats, votes
  from election_result
  where alliance_id is not NULL;

DROP VIEW IF EXISTS election_results_better;
CREATE VIEW election_results_better as
  (select * from fixed_nulls) UNION (select * from election_result_no_null);

DROP VIEW IF EXISTS alliances_sum;
CREATE VIEW alliances_sum as
  select election_id,  alliance_id, SUM(seats), SUM(votes)
  from election_results_better
  group by election_id, alliance_id;

-- the answer to the query
--insert into q5
