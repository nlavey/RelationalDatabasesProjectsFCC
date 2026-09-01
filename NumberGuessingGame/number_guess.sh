#!/bin/bash

# Database connection variable
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if username exists in database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]]
then
  # If user doesn't exist
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  # Get the new user_id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # If user exists, fetch games played and best game (fewest guesses)
  GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM games WHERE user_id=$USER_ID")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id=$USER_ID")
  # If they haven't finished a game yet, set best_game to 0 or leave it empty
  if [[ -z $BEST_GAME ]]
  then
    BEST_GAME=0
  fi
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the game loop
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true
do
  read GUESS
  ((NUMBER_OF_GUESSES++))
  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  # Check if guess is correct
  elif [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    break
  # Check if guess is too high
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  # Check if guess is too low
  else
    echo "It's higher than that, guess again:"
  fi
done

# Print winning message
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

# Save game data to the database
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES)")
