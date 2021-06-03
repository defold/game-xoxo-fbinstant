local xoxo = require "xoxo.xoxo"
local game = require "xoxo.game.game"
local json = require "fbinstant.utils.json"

local log = print

local M = {}

local PENDING_PLAYER_ID = -1000

local context = {
	id = nil,
	type = nil,
	me = nil,		-- from fbinstant.get_player()
	game = nil,		-- from game.new_game()
}

local function get_image()
	return sys.load_resource("/custom_resources/xoxo.b64")
end

-- handle received match data
-- decode it and pass it on to the game
local function send_match_data()
	if context.game then
		local active_player = game.get_active_player(context.game)
		local other_player = game.get_other_player(context.game)
		local your_turn = active_player.id == context.me.id
		xoxo.match_update(context.game, active_player, other_player, your_turn)
	end
end

local function add_player(id, name, photo)
	game.add_player(context.game, {
		id = id,
		name = name,
		photo = photo
	})
end


local function handle_context(context_id, context_type, callback)
	log("handle_context", context_id, context_type)
	context.id = context_id
	context.type = context_type
	context.me = fbinstant.get_player()

	fbinstant.get_players(function(self, players)
		-- get entry point data
		-- if we have some entry point data then we know this is an active game
		local entry_point_data = fbinstant.get_entry_point_data()
		if entry_point_data then
			context.game = json.decode(entry_point_data)
			local players_in_game = context.game.players
			for _,player in ipairs(players) do
				-- is this a player that we don't have in the entry data?
				-- this happens when the first update has been sent in a match
				-- we need to replace PENDING_PLAYER_ID with the player that got the update
				if player.id ~= players_in_game[1].player
				and player.id ~= players_in_game[2].player then
					if players_in_game[1].id == PENDING_PLAYER_ID then
						players_in_game[1].id = player.id
						players_in_game[1].name = player.name
						players_in_game[1].photo = player.photo
					elseif players_in_game[2].id == PENDING_PLAYER_ID then
						players_in_game[2].id = player.id
						players_in_game[2].name = player.name
						players_in_game[2].photo = player.photo
					end
				end
			end
			-- if the game we loaded was a win or draw we set up for a rematch
			if context.game.winner or context.game.draw then
				context.game = game.rematch(context.game)
			end
		else
			context.game = game.new_game()
			add_player(context.me.id, context.me.name, context.me.photo)
			add_player(PENDING_PLAYER_ID, "Friend", "")
		end
		callback()
	end)
end

-- find an opponent and set up the match
local function find_opponent_and_join_match(match_callback)
	log("find_opponent_and_join_match")
	local options = json.encode({
		minSize = 2,
		maxSize = 2
	})
	fbinstant.choose_context(options, function(self, context_id, context_type)
		if context_id then
			handle_context(context_id, context_type, match_callback)
		else
			log("No context")
			match_callback(false, "No opponent selected")
		end
	end)
end

-- send move as match data
local function send_player_move(row, col)
	-- make the move
	game.player_move(context.game, row, col)

	-- create and send payload
	local text = context.me.name .. " made a move!"
	local cta = "Make your move!"
	local template = "move"
	if context.game.draw then
		text = "The game was a draw!"
		cta = "Play again!"
		template = "draw"
	elseif context.game.winner then
		text = context.me.name .. " won the game!"
		cta = "Play again!"
		template = "win"
	end

	local payload = json.encode({
		action = "CUSTOM",
		image = "data:image/png;base64," .. get_image(),
		cta = cta,
		text = text,
		data = context.game,
		strategy = "IMMEDIATE",
		notification = "PUSH",
		template = template,
	})

	fbinstant.update(payload, function(self, success)
		log("Sending match_data message")
		if not context.game.winner and not context.game.draw then
			fbinstant.quit()
		end
	end)
end


local function fbinstant_login(callback)
	fbinstant.initialize(function(self, success)
		if not success then
			callback(false, "ERROR! Unable to initialize FBInstant")
			return
		end

		fbinstant.start_game(function(self, success)
			if not success then
				callback(false, "ERROR! Unable to start game")
				return
			end
			callback(true)
		end)
	end)
end

function M.start(callback)
	fbinstant_login(function(ok, message)
		if not ok then
			log(message)
			callback(false)
			return
		end
		log("fbinstant login ok")

		-- This will get called by the game when the player pressed the
		-- Join button in the menu.
		xoxo.on_join_match(function(callback)
			log("xoxo.on_join_match")
			find_opponent_and_join_match(callback)
		end)

		-- Called by the game when the player pressed the Leave button
		-- when a game is finished (instead of waiting for the next match).
		xoxo.on_leave_match(function()
			log("xoxo.on_leave_match")
			fbinstant.quit()
		end)

		-- Called by the game when the player is trying to make a move.
		xoxo.on_send_player_move(function(row, col)
			log("xoxo.on_send_player_move")
			send_player_move(row, col)
		end)


		-- get the current context we're in
		-- if the context is THREAD it means we are in a messenger conversation
		-- in this case we handle the context and flag to the game that we are
		-- reconnecting (into an existing or new game with an opponent)
		-- if we are in another kind of context we flag to the game that we are
		-- connected and proceed to let the player chose an opponent
		local context_id, context_type = fbinstant.get_context()
		if context_id and context_type == fbinstant.CONTEXT_THREAD then
			handle_context(context_id, context_type, function()
				timer.delay(1, true, function()
					send_match_data()
				end)
				xoxo.show_game()
				callback(true)
			end)
		else			
			xoxo.show_menu()
			callback(true)
		end
	end)
end


return M
