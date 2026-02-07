-- F3L Training Script (EdgeTX / OpenTX Telemetry Script)
-- Stable training version for F3L
-- Flight: remaining time (freezes at landing), Flight time: duration
-- Clean 1Hz last 15s countdown, no repeated "zero"
-- SA down ends flight only (working time continues)
-- ENTER double-press (while working time runs) = reset flight window to 6:00

------------------------------------------------------------
-- Constants
------------------------------------------------------------
local WORKING_TIME = 540
local MAX_FLIGHT   = 360

local ELEV_SOURCE  = "ele"
local ELEV_THRESH  = 80

local SF_SOURCE    = "sf"
local SA_SOURCE    = "sa"

local VOICE_MIN_GAP = 0.7
local BACK_CONFIRM_WINDOW = 2.0
local ENTER_DOUBLE_WINDOW = 1.0   -- seconds for double-press ENTER

------------------------------------------------------------
-- State
------------------------------------------------------------
local state = {
  lastFlightDuration = nil,

  windowRunning = false,
  windowStart   = 0,

  flightStarted  = false,
  flightStart    = 0,      -- float seconds
  flightStartSec = 0,      -- integer seconds (for clean 1Hz countdown)
  flightEnded    = false,
  flightEnd      = 0,

  armLaunch      = false,

  sfPrev         = false,
  saPrev         = 0,

  lastFlightRemMin = nil,
  lastFlightRemSec = nil,

  lastVoiceAt    = -9999,

  lastCountdownSpoken = nil,

  backArmedUntil     = 0,
  showBackHintUntil  = 0,

  enterArmedUntil    = 0  -- for ENTER double-press
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function nowSeconds()
  return getTime() / 100
end

local function nowIntSeconds()
  return math.floor(nowSeconds() + 0.0001)
end

local function formatTime(sec)
  if sec == nil or sec ~= sec or sec < 0 then sec = 0 end
  local m = math.floor(sec / 60)
  local s = math.floor(sec % 60)
  return string.format("%02d:%02d", m, s)
end

local function getElevPercent()
  local v = getValue(ELEV_SOURCE)
  if v == nil then return 0 end
  return v / 10.24
end

local function canSpeak(t)
  return (t - state.lastVoiceAt) >= VOICE_MIN_GAP
end

local function markSpoke(t)
  state.lastVoiceAt = t
end

local function hardReset()
  state.lastFlightDuration = nil

  state.windowRunning = false
  state.windowStart   = 0

  state.flightStarted  = false
  state.flightStart    = 0
  state.flightStartSec = 0
  state.flightEnded    = false
  state.flightEnd      = 0

  state.armLaunch = false

  state.lastFlightRemMin = nil
  state.lastFlightRemSec = nil
  state.lastVoiceAt      = -9999

  state.lastCountdownSpoken = nil

  state.backArmedUntil    = 0
  state.showBackHintUntil = 0
  state.enterArmedUntil   = 0

  playTone(500, 180, 0, PLAY_BACKGROUND)
end

-- Reset ONLY flight (keep working time running)
local function resetFlightOnly()
  state.flightStarted  = false
  state.flightStart    = 0
  state.flightStartSec = 0
  state.flightEnded    = false
  state.flightEnd      = 0

  state.lastFlightDuration = nil

  state.lastFlightRemMin = nil
  state.lastFlightRemSec = nil
  state.lastCountdownSpoken = nil
  state.lastVoiceAt = -9999

  -- allow new launch within current working time
  state.armLaunch = state.windowRunning and true or false

  playTone(1000, 150, 0, PLAY_BACKGROUND)
  playTone(1000, 150, 180, PLAY_BACKGROUND)
end

local function getFlightElapsed(t)
  if not state.flightStarted then return 0 end
  if state.flightEnded then
    return state.flightEnd - state.flightStart
  else
    return t - state.flightStart
  end
end

local function getFlightRemaining(t)
  if not state.flightStarted then return MAX_FLIGHT end
  local rem = MAX_FLIGHT - getFlightElapsed(t)
  if rem < 0 then rem = 0 end
  return rem
end

------------------------------------------------------------
-- Input handling
------------------------------------------------------------
local function handleInputs(event)
  local t = nowSeconds()

  -- BACK double press = reset all
  if event == EVT_EXIT_BREAK then
    if state.backArmedUntil > t then
      hardReset()
      return
    else
      state.backArmedUntil = t + BACK_CONFIRM_WINDOW
      state.showBackHintUntil = t + BACK_CONFIRM_WINDOW
      playTone(900, 120, 0, PLAY_BACKGROUND)
      return
    end
  end

  -- ENTER short press
  if event == EVT_ENTER_BREAK then
    -- If idle: start working time
    if (not state.windowRunning) and state.windowStart == 0 then
      state.windowRunning = true
      state.windowStart   = t
      state.armLaunch     = true
      state.enterArmedUntil = 0
      playTone(1200, 200, 0, PLAY_BACKGROUND)
      return
    end

    -- If working time is running: use ENTER double-press to reset flight only
    if state.windowRunning then
      if state.enterArmedUntil > t then
        resetFlightOnly()
        state.enterArmedUntil = 0
      else
        state.enterArmedUntil = t + ENTER_DOUBLE_WINDOW
        playTone(700, 60, 0, PLAY_BACKGROUND) -- tiny "armed" tick
      end
    end
  end

  -- SA down = landing: end flight ONLY (do not stop working time)
  local sa = getValue(SA_SOURCE)
  if sa ~= nil and sa ~= state.saPrev then
    if sa < 0 and state.flightStarted and (not state.flightEnded) then
      state.flightEnded = true
      state.flightEnd   = t
      state.lastFlightDuration = state.flightEnd - state.flightStart
      playTone(800, 200, 0, PLAY_BACKGROUND)
      -- working time continues
    end
    state.saPrev = sa
  end

  -- SF momentary = speak remaining working time
  local sf = getValue(SF_SOURCE)
  local sfActive = (sf ~= nil and sf < 0)

  if sfActive and (not state.sfPrev) then
    local remaining = WORKING_TIME
    if state.windowRunning then
      remaining = WORKING_TIME - (t - state.windowStart)
    elseif state.windowStart > 0 then
      remaining = 0
    end
    if remaining < 0 then remaining = 0 end

    if canSpeak(t) then
      playDuration(math.floor(remaining + 0.5))
      markSpoke(t)
    end
  end

  state.sfPrev = sfActive
end

------------------------------------------------------------
-- Flight voice cues (clean 1Hz countdown)
------------------------------------------------------------
local function handleFlightVoice(t)
  if not (state.flightStarted and not state.flightEnded) then return end

  local nowSec = nowIntSeconds()
  local elapsedSec = nowSec - state.flightStartSec
  if elapsedSec < 0 then elapsedSec = 0 end

  local remaining = MAX_FLIGHT - elapsedSec

  if remaining <= 0 then
    state.flightEnded = true
    state.flightEnd = state.flightStart + MAX_FLIGHT
    state.lastFlightDuration = state.flightEnd - state.flightStart
    playTone(600, 350, 0, PLAY_BACKGROUND)
    return
  end

  local remMin = math.floor(remaining / 60)
  local remSec = remaining % 60

  -- Full minutes 5..1 at mm:00
  if remSec == 0 and remMin > 0 and remMin < (MAX_FLIGHT / 60) then
    if state.lastFlightRemMin ~= remMin and canSpeak(t) then
      playDuration(remMin * 60)
      markSpoke(t)
      state.lastFlightRemMin = remMin
    end
  end

  -- 30s / 20s
  if remMin == 0 and (remaining == 30 or remaining == 20) then
    if state.lastFlightRemSec ~= remaining and canSpeak(t) then
      playDuration(remaining)
      markSpoke(t)
      state.lastFlightRemSec = remaining
    end
  end

  -- Last 15 seconds: speak only on change
  if remaining <= 15 then
    if state.lastCountdownSpoken ~= remaining then
      playNumber(remaining, 0, 0)
      state.lastCountdownSpoken = remaining
    end
  else
    state.lastCountdownSpoken = nil
  end
end

------------------------------------------------------------
-- State update
------------------------------------------------------------
local function updateState()
  local t = nowSeconds()

  if state.backArmedUntil > 0 and t >= state.backArmedUntil then
    state.backArmedUntil = 0
  end

  if state.enterArmedUntil > 0 and t >= state.enterArmedUntil then
    state.enterArmedUntil = 0
  end

  local elev = getElevPercent()

  -- Launch detection
  if state.windowRunning then
    if elev < (ELEV_THRESH - 10) then
      state.armLaunch = true
    end

    if state.armLaunch and (not state.flightStarted) and elev >= ELEV_THRESH then
      state.flightStarted  = true
      state.flightStart    = t
      state.flightStartSec = nowIntSeconds()
      state.flightEnded    = false
      state.flightEnd      = 0
      state.armLaunch      = false

      state.lastFlightRemMin = nil
      state.lastFlightRemSec = nil
      state.lastCountdownSpoken = nil

      playTone(1500, 200, 0, PLAY_BACKGROUND)
    end
  end

  -- Working time expiry: stop working time, and stop flight if still running
  if state.windowRunning and (t - state.windowStart) >= WORKING_TIME then
    state.windowRunning = false
    if state.flightStarted and not state.flightEnded then
      state.flightEnded = true
      state.flightEnd   = state.windowStart + WORKING_TIME
      state.lastFlightDuration = state.flightEnd - state.flightStart
      playTone(600, 350, 0, PLAY_BACKGROUND)
    else
      playTone(600, 200, 0, PLAY_BACKGROUND)
    end
  end

  handleFlightVoice(t)
end

------------------------------------------------------------
-- UI
------------------------------------------------------------
local function draw()
  lcd.clear()
  lcd.drawText(2, 0, "F3L Training", MIDSIZE)

  local t = nowSeconds()

  if state.showBackHintUntil > t then
    lcd.drawText(2, 18, "Press BACK again", 0)
    lcd.drawText(2, 30, "to reset", 0)
    return
  end

  local work = WORKING_TIME
  if state.windowRunning then
    work = WORKING_TIME - (t - state.windowStart)
  elseif state.windowStart > 0 then
    work = 0
  end
  if work < 0 then work = 0 end

  lcd.drawText(2, 16, "Working:", 0)
  lcd.drawText(70, 16, formatTime(work), 0)

  local flightRem = getFlightRemaining(t)
  lcd.drawText(2, 28, "Flight :", 0)
  lcd.drawText(70, 28, formatTime(flightRem), 0)

  if state.lastFlightDuration ~= nil then
    lcd.drawText(2, 40, "Flight time:", 0)
    lcd.drawText(70, 40, formatTime(state.lastFlightDuration), 0)
  end

  lcd.drawText(2, 55, "ENTER start | SA land | SF WT", SMLSIZE)
end

------------------------------------------------------------
-- init / run
------------------------------------------------------------
local function init()
  local sf = getValue(SF_SOURCE)
  state.sfPrev = (sf ~= nil and sf < 0)

  local sa = getValue(SA_SOURCE)
  if sa ~= nil then state.saPrev = sa end
end

local function run(event)
  handleInputs(event)
  updateState()
  draw()
end

return { run = run, init = init }
