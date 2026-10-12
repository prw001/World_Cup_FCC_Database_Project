#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

FILEPATH="games.csv"
# Do not change code above this line. Use the PSQL variable above to query your database.
# Read in CSV values

echo $($PSQL "TRUNCATE TABLE games, teams RESTART IDENTITY;")
PARSE_FILE_DATA()
{
  #REGEX="^([0-9]+),([A-Z][a-z]+|[A-Z][a-z]+\-[A-Z][a-z]+|[A-Z][a-z]+\s[A-Z][a-z]+),([A-Z][a-z]+|[A-Z][a-z]+\s[A-Z][a-z]+),([A-Z][a-z]+|[A-Z][a-z]+\s[A-Z][a-z]+),([0-9]+),([0-9]+)$"
  while IFS="," read -r YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS; do
  #parse each section and insert
  #skip the header
  if [[ "$YEAR" != "year" ]]
  then
    #Uncomment the below line only for testing the IFS read values
    #echo -e "\nYear: $YEAR\nRound: $ROUND\nWinning team: $WINNER | Losing Team: $OPPONENT\nWinner score: $WINNER_GOALS | Loser score: $OPPONENT_GOALS"

    #Get team ids
    #Try to get winning team
    WINNER_TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    #if doesn't exist, add to table
    if [[ -z $WINNER_TEAM_ID ]]
    then
      WINNER_INSERTION_RESULT=$($PSQL "INSERT INTO teams (name) VALUES ('$WINNER')")
      WINNER_TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER'")
    fi
    #Try to get opposing team
    OPPONENT_TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    #if doesn't exist, add to table
    if [[ -z $OPPONENT_TEAM_ID ]]
    then
      OPPONENT_INSERTION_RESULT=$($PSQL "INSERT INTO teams (name) VALUES ('$OPPONENT') RETURNING team_id")
      OPPONENT_TEAM_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT'")
    fi
    #Insert game results into game table
    TABLE_INSERT_RESULT=$($PSQL "INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($YEAR, '$ROUND', $WINNER_TEAM_ID, $OPPONENT_TEAM_ID, $WINNER_GOALS, $OPPONENT_GOALS)")
  fi
  done < "$FILEPATH"
}

PARSE_FILE_DATA