-- Program Information
meta={
  name="Immersive Engineering Mixer Control"
  author="JoshBoshGames",
  version="v0.1.0",
  view_url="https://github.com/JoshBoshGames/minecraft-lua/blob/main/opencomputers/0826-Ind/mixer.lua"
  raw_update_url="https://raw.githubusercontent.com/JoshBoshGames/minecraft-lua/refs/heads/main/opencomputers/0826-Ind/mixer.lua"
}

--Initialisation
  --redstoneSide="west"
  --Component Acquisition
    os = require("os")
    component = require("component")
    computer = require("computer")
    term = require("term")
    rs = component.redstone
    sides = require("sides")

  --Acquire meta info
    _ARGS, _OPS = shell.parse(...)
    

--getData
function getData()
  progress = 0
  for i=1,8 do
    progress = math.max(component.ie_mixer.getInputStack(i).progress,progress)
  end
end

--Watchdog
function watchdog()
  memCap = computer.totalMemory()
  memFree = computer.freeMemory()
  memUse = memCap-memFree
  memString = "RAM: "..memUse.."/"..memCap
  --autoreboot
  if memUse/memCap>0.9 then
    computer.shutdown(true)
  end
end

--Monitoring
function monitor()
  if term.isAvailable() then
    term.clear()
    term.write("JBG-S Mixer - "..memString.."\n")
    term.write("Progress "..progress.."\n")
  end
end

--ManageMachine
function manageMachine()
  if progress <= 100 then
    rs.setOutput(sides[redstoneSide],15)
  else
    rs.setOutput(sides[redstoneSide],0)
  end
end

--MAIN PROCESS

while true do
  watchdog()
  getData()
  monitor()
  manageMachine()
  os.sleep(0.1)
end
