--[[
  Copyright 2020 The Defold Foundation Authors & Contributors

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
]] --

local tictactoe = require("tictactoe_state")
local nk = require("nakama")

local M = {}

local OP_CODE_MOVE = 1
local OP_CODE_STATE = 2


local function pprint(t)
    if type(t) ~= "table" then
        nk.logger_info(tostring(t))
    else
        for k, v in pairs(t) do
            nk.logger_info(string.format("%s = %s", tostring(k), tostring(v)))
        end
    end
end

local function broadcast_gamestate_to_recipient(dispatcher, gamestate, recipient)
    nk.logger_info("broadcast_gamestate")
    local active_player = tictactoe.get_active_player(gamestate)
    local other_player = tictactoe.get_other_player(gamestate)
    local your_turn = active_player.user_id == recipient.user_id
    local message = {
        state = gamestate,
        active_player = active_player,
        other_player = other_player,
        your_turn = your_turn,
    }
    local encoded_message = nk.json_encode(message)
    dispatcher.broadcast_message(OP_CODE_STATE, encoded_message, { recipient })
end

local function broadcast_gamestate(dispatcher, gamestate)
    local player = tictactoe.get_active_player(gamestate)
    local opponent = tictactoe.get_other_player(gamestate)
    broadcast_gamestate_to_recipient(dispatcher, gamestate, player)
    broadcast_gamestate_to_recipient(dispatcher, gamestate, opponent)
end

function M.match_init(context, setupstate)
    nk.logger_info("match_init")
    local gamestate = tictactoe.new_game()
    local tickrate = 10 -- per sec
    local label = ""
    return gamestate, tickrate, label
end

function M.match_join_attempt(context, dispatcher, tick, gamestate, presence, metadata)
    nk.logger_info("match_join_attempt")
    local acceptuser = true
    return gamestate, acceptuser
end

function M.match_join(context, dispatcher, tick, gamestate, presences)
    nk.logger_info("match_join")
    for _, presence in ipairs(presences) do
        tictactoe.add_player(gamestate, presence)
    end
    if tictactoe.player_count(gamestate) == 2 then
        broadcast_gamestate(dispatcher, gamestate)
    end
    return gamestate
end

function M.match_signal(context, dispatcher, tick, gamestate, presences)
    nk.logger_info("match_signal")
end

function M.match_leave(context, dispatcher, tick, gamestate, presences)
    nk.logger_info("match_leave")
    -- end match if someone leaves
    return nil
end

function M.match_loop(context, dispatcher, tick, gamestate, messages)
    nk.logger_info(string.format("match_loop: tick %s", tick))

    for _, message in ipairs(messages) do
        nk.logger_info(string.format("Received %s from %s", message.data, message.sender.username))
        pprint(message)

        if message.op_code == OP_CODE_MOVE then
            local decoded = nk.json_decode(message.data)
            local col = decoded.col
            local row = decoded.row
            gamestate = tictactoe.player_move(gamestate, col, row)

            broadcast_gamestate(dispatcher, gamestate)
        end
    end

    return gamestate
end

function M.match_terminate(context, dispatcher, tick, gamestate, grace_seconds)
    nk.logger_info("match_terminate")
    local message = "Server shutting down in " .. grace_seconds .. " seconds"
    dispatcher.broadcast_message(OP_CODE_STATE, message)
    return nil
end

return M
