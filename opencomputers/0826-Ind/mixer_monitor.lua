-- Program Information
meta={
  name="Immersive Engineering Mixer Control"
  author="JoshBoshGames",
  version="v0.1.0",
  view_url="https://github.com/JoshBoshGames/minecraft-lua/blob/main/opencomputers/0826-Ind/mixer_monitor.lua"
  raw_update_url="https://raw.githubusercontent.com/JoshBoshGames/minecraft-lua/refs/heads/main/opencomputers/0826-Ind/mixer_monitor.lua"
}

--Initialisation
  --redstoneSide="west"
  --Library Requisition
    os = require("os")
    component = require("component")
    computer = require("computer")
    term = require("term")
    rs = component.redstone
    sides = require("sides")
    
  --Acquire/Provide meta info
    ARGS, OPTS = shell.parse(...) --Pulls CLI options and arguments
    if OPTS.help==true then --Help page
      print(
        "Usage: mixer_monitor [OPTION] [OPTION]...\n"..
        "--activity_side=[SIDE]   Set the activity reporting side for redstone out\n"..
        "--validity_side=[SIDE]   Set the valid_recipe reporting side for redstone out\n"..
        "--enable_side=[SIDE]     Set the redstone machine_enable side for redstone in\n"..
        "--help                     Show this message and then close\n"
      )
      os.exit()
    else
      if #OPTS==0 then --Passive Mode Warning
        print(
          "WARNING - Program running with no options, will only read data\n"..
          "For more information, run: mixer_monitor --help"
        )
        os.sleep(3)
      end
    end
  --Mode Switching
    mode={}
    mode.activity = sides[OPTS.activity_side]~=nil
    mode.validity = sides[OPTS.validity_side]~=nil
    mode.enable = sides[OPTS.enable_side]~=nil
    
--Runtime Functions
  --Memory Watchdog, reboots if over 95% limit
function watchdog()
  local data={}
  data.memCap = computer.totalMemory()
  data.memFree = computer.freeMemory()
  data.memUse = memCap-memFree
  data.memString = "RAM: "..memUse.."/"..memCap
  --autoreboot
  if memUse/memCap>0.95 then
    computer.shutdown(true)
  end
  return(data)
end

--Machine Data Acquisition
function getData()
  local data={}
  data.energyStored=
  data.activity = component.ie_mixer.
end


--OLD CODE

--getData


--Watchdog

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
