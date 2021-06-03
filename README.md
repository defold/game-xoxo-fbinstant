# XOXO Facebook Instant client
This is a Tic Tac Toe game made with [Defold for Facebook Instant Games](https://defold.com/extension-fbinstant/).

## Game client
This project uses the generic Tic Tac Toe example game which can be found [in this repository](https://www.github.com/defold/game-xoxo).

## Implementation details

### Step 1: Init and game start
The game starts by calling `fbinstant.initialize()` and `fbinstant.start_game()`:

https://github.com/defold/game-xoxo-fbinstant/blob/master/game/xoxo_fbinstant.lua#L141-L156

### Step 2: Get the context
Next step is to checks what context we're in, using `fbinstant.get_context()`. If we're in a THREAD context it's a messenger conversation with a person which means we're also ready to play a game. If we're in some other context we need to find a friend to play with.

https://github.com/defold/game-xoxo-fbinstant/blob/master/game/xoxo_fbinstant.lua#L207

### Step 3: Finding a friend
We use `fbinstant.choose_context()` to select a friend to play with. We specifically define the sought after context to contain exactly two people (ie no group conversations or similar). We then proceed with the game setup.

https://github.com/defold/game-xoxo-fbinstant/blob/master/game/xoxo_fbinstant.lua#L92

### Step 3: Game setup
The game state is passed to the context as something called entry point data, which we can read using `fbinstant.get_entry_point_data()`. If the context contains entry point data we use this to set up the game with the state in the data. If there is no entry point data we set up a new game. We also get the players in the context using `fbinstant.get_players()`. The number of players can be either one or two, and one of them will always be the logged in player. If there's only the logged in player it means that we must make our first move and send that to the friend before the friend becomes part of the context.

https://github.com/defold/game-xoxo-fbinstant/blob/master/game/xoxo_fbinstant.lua#L48-L51

### Step 4: Gameplay update
Finally, when the player has made a move we update the game state and update the context using `fbinstant.update()`:

https://github.com/defold/game-xoxo-fbinstant/blob/master/game/xoxo_fbinstant.lua#L132
