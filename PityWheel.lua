--- STEAMODDED HEADER
--- MOD_NAME: Wheel of Fortune Tracker + Guarantee
--- MOD_ID: wheel_of_fortune_tracker_plus_guarantee
--- MOD_AUTHOR: [sabslikesobs]
--- MOD_DESCRIPTION: Tracks Wheel of Fortune failure rate. Optionally, enforce 1/4 success rate so that three nopes in a row guarantee success.

-- Try the seed 3GXQ328W to test this mod and others that affect Wheel of
-- Fortune: with the Plasma deck, play 3-of-a-kind aces on the first blind to
-- win instantly; reroll the shop once and buy The Fool; skip the next blind
-- and use Judgement to get a Joker; use The Wheel of Fortune to turn it
-- into a Foil; use The Fool to get another Wheel of Fortune; discard to get a
-- flush of Diamonds and beat The Psychic in 1 turn; you can then reroll once,
-- sell your Joker, and then buy another. Your second Wheel of Fortune will fail,
-- and you can use that to test repeating behavior. You can return to the main
-- menu repeatedly to increment the metrics without losing game state.


local config = {
	-- If true, force Wheel of Fortune to succeed based on force_one_in_this_many.
	-- Data is not tracked within each game save, so if you want to cheat, you can
	-- quit to the main menu after Wheel of Fortune fails and try again until it hits.
	--
	-- If false, add success rate to Wheel of Fortune's card description.
	-- There is no need to track success rate when true because of the forced hits.
	--
	-- Both options reset all data whenever balatro.exe launches and do not reset
	-- even if you start a new game, etc. -- I'm not really interested in exploring
	-- the save system to see if that can be done.
	enable_pity = false,

	-- Configure the maximum number of failures before Wheel of Fortune succeeds.
	-- Wheel of Fortune cannot fail more than (force_one_in_this_many - 1) times in a row.
	-- To make Wheel of Fortune succeed every time, set this to 1.
	--
	-- The default is G.P_CENTERS.c_wheel_of_fortune.config.extra, which is 4, the same
	-- value that informs the "1/4" text on the card (see c_wheel_of_fortune in game.lua)
	--
	-- The Joker "Oops! All 6s" will halve the minimum failure rate, rounded down. The default
	-- value of 4 will be halved to 2, meaning Wheel of Fortune cannot fail twice in a row.
	force_one_in_this_many = G.P_CENTERS.c_wheel_of_fortune.config.extra,
}


-- Tracking data
local pity = {
	sequential_failed_rolls = 0,
	total_rolls = 0,
	successful_rolls = 0,
}

-- Saves the tracking data to a file. 
function write(total_rolls, successful_rolls)
	local f = assert(io.open("wheel_save.txt", "w"))
	f:write(total_rolls.. "", "\n")
	--print ("wrote " .. total_rolls)
	f:write(successful_rolls.. "", "\n")
	--print ("wrote " .. successful_rolls)
	f:close()
end

-- Reads the tracking data from a file.
function read()
	local f = assert(io.open("wheel_save.txt", "r"))
	pity.total_rolls = f:read("*line")
	--print (pity.total_rolls.. "")
	pity.successful_rolls = f:read("*line")
	--print (pity.successful_rolls.. "")
	f:close()
end

-- Update Wheel of Fortune description with a slot for this mod's custom message.
-- Each description has styling and variable slots to insert current game state.
-- See "c_wheel_of_fortune" in localization/en-us.lua
local desc = G.localization.descriptions["Tarot"]["c_wheel_of_fortune"].text
-- WoF already has 2 variable slots (#1# and #2#) for localization variables,
-- which create the "1/4" probability indicator in the card description.
-- See "The Wheel of Fortune" in functions/common_events.lua (FYI,
-- unzip balatro.exe). This line adds one more gray (C:inactive) text line to
-- the bottom of the card.
desc[#desc+1] = "{C:inactive}#3#"

-- Inject my custom extra footer whenever Wheel of Fortune's description appears on the screen.
-- generate_card_ui() in functions/common_events.lua creates the cards. To get the description
-- text, generate_card_ui() sets loc_vars (localize variables) depending on the
-- card's name and ability, then calls localize(). Since I can't add anything to
-- loc_vars inside of the enormous generate_card_ui() without copying the
-- entire function, I overwrite localize() to inject one more value before the
-- real localize() is called via original_localize(). 
local original_localize = localize
function localize(args, misc_cat)
	-- args.key turns out to be the unique card identifier, but I guessed that was true
	read()
	if args.type == "descriptions" and args.key == "c_wheel_of_fortune" then
		-- I update this every time just in case G.GAME.probabilities.normal has changed lately
		local actual_force_one_in_this_many = math.max(math.floor(config.force_one_in_this_many / G.GAME.probabilities.normal), 1)
		local append_message = ""
		local f = pity.sequential_failed_rolls
		local s = pity.successful_rolls
		local t = pity.total_rolls
		if not config.enable_pity then
			if t == 0 then
				append_message = "Will you spin the wheel of fortune...?"
			else
				append_message = "" .. t-s .. " nope(s), " .. s .. " hit(s) (" .. math.floor(100 * (t-s) / t) .. "% nope rate)"
			end
		elseif pity.sequential_failed_rolls == actual_force_one_in_this_many - 1 then
			append_message = "I promise it'll work this time!"
		elseif actual_force_one_in_this_many - pity.sequential_failed_rolls - 1 == 1 then
			append_message = "One nope left, then it's guaranteed!"
		else
			append_message = "" .. actual_force_one_in_this_many - pity.sequential_failed_rolls - 1 .. " nopes left until freebie."
		end
		args.vars[#args.vars+1] = append_message
	end
	return original_localize(args, misc_cat)
end

-- Override pseudorandom() to track failures and force hits for Wheel of Fortune.
-- See pseudorandom('wheel_of_fortune') in Card:use_consumeable in card.lua.
local original_pseudorandom = pseudorandom
function pseudorandom(seed, min, max)
	read()
	local actual = original_pseudorandom(seed, min, max)
	if seed == 'wheel_of_fortune' then
		-- I update this every time just in case G.GAME.probabilities.normal has changed lately
		local actual_force_one_in_this_many = math.max(math.floor(config.force_one_in_this_many / G.GAME.probabilities.normal), 1)
		pity.total_rolls = pity.total_rolls + 1
		if config.enable_pity and pity.sequential_failed_rolls == actual_force_one_in_this_many - 1 then
			actual = 0.0
		end
		if actual < G.GAME.probabilities.normal/G.P_CENTERS.c_wheel_of_fortune.config.extra then
			pity.successful_rolls = pity.successful_rolls + 1
			pity.sequential_failed_rolls = 0
		else
			pity.sequential_failed_rolls = pity.sequential_failed_rolls + 1
		end
	end
	-- print("Total rolls: " .. pity.total_rolls .. ", successful rolls: " .. pity.successful_rolls)
	write(pity.total_rolls, pity.successful_rolls)
	return actual
end

-- Overwrite Card:use_consumeable just to show a message when the pity effect fires.
local original_use_consumeable = Card.use_consumeable
function Card:use_consumeable(area, copier)

	-- Determine whether or not to show the attention_text before calling original_use_consumeable, since
	-- original_use_consumeable calls pseudorandom('wheel_of_fortune'), which will wipe the variables
	-- if pity fires.
	local show_pity = self.ability.name == "The Wheel of Fortune" and config.enable_pity and pity.sequential_failed_rolls == config.force_one_in_this_many - 1

	original_use_consumeable(self, area, copier)

	if show_pity then
		local used_tarot = copier or self
		G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
			attention_text({
					text = "That was pity!",
					scale = 1.3, 
					hold = 2.4,
					major = used_tarot,
					backdrop_colour = G.C.SECONDARY_SET.Tarot,
					-- Resolved conditional values from the "Nope!" text. See 'k_nope_ex' in card.lua
					align = 'cm',
					offset = {x = 0, y = -0.2},
					silent = true
				})
			G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
			play_sound('tarot1', 0.76, 0.4); return true end}))
			play_sound('tarot1', 1, 0.4)
			used_tarot:juice_up(0.3, 0.5)
		return true end }))
		delay(0.6)
	end
end

