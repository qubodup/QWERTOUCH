-- only needed for substring function sub, which is not used any more
--require "string"

function round2(num, idp)
  return tonumber(string.format("%." .. (idp or 0) .. "f", num))
end

function love.load()

  love.graphics.setColor(255, 255, 255)
  love.graphics.setBackgroundColor(25, 25, 25)

  debug = false

  width = 640
  height = 480

  --success = love.window.setMode(width, height, {fullscreen=true})
  success = love.window.setMode(width, height)

  tutorial = "QWERTOUCH\n\nIn this game, you have to touch the keyboard, where the letter is, which you hear me say.\n\nPress a to start."
  tutstep = 0 -- tutorial letter counter

  level = 1
  gameover = false

  levels = {3, 2, 1, .8}

  -- keeps track of player reaction to hearing letters
  pressed = false

  -- number of successes minus failures
  score = 1

  tutlen = tutorial:len()

  inter = 0.4

  keys = {
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
  }

  currentkey = "a"

  keyvoice = {}
  feedback = {}

  -- load audio
  for i=1,4 do
    keyvoice[i] = {}
    for j,v in pairs(keys) do
      keyvoice[i][v] = love.audio.newSource("snd/" .. v .. i .. ".ogg", "stream")
      keyvoice[i][v]:setLooping(false)
    end
    feedback[i] = {}
    feedback[i].yes = love.audio.newSource("snd/yes" .. i .. ".ogg", "stream")
    feedback[i].yes:setLooping(false)
    feedback[i].yes:setVolume(0.5)
    feedback[i].no = love.audio.newSource("snd/no" .. i .. ".ogg", "stream")
    feedback[i].no:setLooping(false)
    feedback[i].no:setVolume(0.1)
  end

  intro = love.audio.newSource("snd/intro.ogg", "stream")

  -- state can be pre, starting, game, end, over
  state = "pre"
  timer = 0
  gametimer = 30
  -- inital letter timer
  lettertimer = 0 --levels[level]
  successtime = 0
  successrate = 0

  -- timer for the end sequence. we're gonna do some weird shit to it!
  endtimerlimit = .5

end

function cplay(letter, tone)
  if letter ~= " " then
    keyvoice[tone][letter]:play()
  end
end

function love.keypressed(key)
   if state == "pre" and key == "a" then
      if intro:isPlaying() then
        intro:stop()
      end
     state = "starting"
     timer = 3
   elseif state == "over" and key == "r" then
     love.load()
   elseif key == "escape" then
     love.event.push("quit")
   end
end

function love.update(dt)
  if state == "pre" then
    timer = timer + dt

    -- if enough time has passed since the last step
    -- too confusing to read intro letter by letter
    --[[
    if inter <= timer then
      timer = 0
      if tutstep == tutlen then
        tutstep = 0
      end
      tutstep = tutstep + 1
      letter = tutorial:sub(tutstep, tutstep)
      cplay(letter, level)
    end
    ]]--
    -- just read the phrase
    if tutstep == 0 then
      intro:play()
      tutstep = 1
    end
  elseif state == "starting" then
    timer = timer - dt
    if timer < 0 then
      state = "game"
    end
  elseif state == "game" then
    lettertimer = lettertimer - dt
    if lettertimer <= 0 then
      lettertimer = levels[level]
      if not pressed then
        score = score - 1
        feedback[level].no:play()
        -- don't die too hard
        if score < 0 then score = 0 end
      end
      pressed = false

      -- set new key
      currentkey = keys[ math.random( #keys ) ]

      -- process current score status
      if score >= 40 then
        gameover = true
        score = 40
      elseif score >= 30 then level = 4
      elseif score >= 20 then level = 3
      elseif score >= 10 then level = 2
      else level = 1 end

      -- process game win state (level 5)
      if gameover then
        state = "end"
	timer = 0
      else
	cplay(currentkey, level)
      end

    end
    -- check player press during game
    for i,v in pairs(keys) do
      if love.keyboard.isDown(v) then
        if not pressed then
          if currentkey == v then
            score = score + 2
            feedback[level].yes:play()
          else
            score = score - 1
            feedback[level].no:play()
            -- don't die too hard
            if score < 0 then score = 0 end
          end
        end
        pressed = true
      end
    end

    if timer < 0 then
      timer = 1 + math.random(10)/10
    end
    timer = timer - dt
  elseif state == "end" then
    timer = timer - dt
    if timer <= 0 then
      timer = endtimerlimit
      endtimerlimit = endtimerlimit * 0.95
      currentkey = keys[ math.random( #keys ) ]
      cplay(currentkey, 4)
      if endtimerlimit < 0.0005 then
        state = "over"
      end
    end
  end
end

function love.draw()
  if state == "pre" then
    love.graphics.printf(tutorial, width/4, height/4 + height/16, width/2, "center")
  elseif state == "starting" then
    love.graphics.printf(math.ceil(timer), width/4, height/4 + height/16, width/2, "center")
  elseif state == "game" then
    --love.graphics.printf(currentkey .. "\n" .. round2(lettertimer, 2) .. "\n" .. score .. "\nlvl " .. level .. "/4", width/2-100, height/2-5, 200, "center")
    -- don't make it too easy now...
    love.graphics.printf("Score: " .. score .. " of 40", width/2-100, height/2-5, 200, "center")
  elseif state == "end" then
    love.graphics.printf("Oh, my...\n\n-George Hosato Takei", width/4, height/4 + height/16, width/2, "center")
  elseif state == "over" then
    love.graphics.printf("\n\nQWERTOUCH is based on the theme \"Touch Me\"\n\nPress R to restart", width/4, height/4 + height/16, width/2, "center")
  end
end
