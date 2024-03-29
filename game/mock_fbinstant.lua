local mock = require "fbinstant.utils.mock"
local game = require "xoxo.game.game"

if fbinstant.mock then
	local ME = {
		name = "Player 1",
		id = "100000000001fake",
		photo = "http://i.pravatar.cc/200?u=123",
		locale = "en_US",
	}
	local PLAYER2 = {
		name = "Player 2",
		id = "100000000002fake",
		photo = "http://i.pravatar.cc/200?u=124",
		locale = "en_US",
	}

	-- this is the logged in player
	fbinstant.PLAYER = ME

	-- these are the players in the current context (fbinstant.get_players())
	fbinstant.PLAYERS = {
		ME, PLAYER2
	}

	-- the current context
	fbinstant.CONTEXT = {
		id = "123456fake",
		--type = fbinstant.CONTEXT_SOLO,
		type = fbinstant.CONTEXT_THREAD,
		size = 2,
	}

	local g = game.new_game()
	game.add_player(g, ME)
	game.add_player(g, PLAYER2)
	fbinstant.ENTRY_POINT_DATA = g
end