-- Program Information
meta={}
  meta.name = "Immersive Engineering Mixer Control"
  meta.author = "JoshBoshGames"
  meta.version = "v0.1.0"
  meta.view_url = "https://github.com/JoshBoshGames/minecraft-lua/blob/main/opencomputers/0826-Ind/mixer_monitor.lua"
  meta.raw_update_url = "https://raw.githubusercontent.com/JoshBoshGames/minecraft-lua/refs/heads/main/opencomputers/0826-Ind/mixer_monitor.lua"

--Initialisation
  --redstoneSide="west"
  --Library Requisition
    os = require("os")
    component = require("component")
    computer = require("computer")
    term = require("term")
    rs = component.redstone
    sides = require("sides")
    shell = require("shell")
    
  --Acquire/Provide meta info
    ARGS, OPTS = shell.parse(...) --Pulls CLI options and arguments
    if OPTS.help==true then --Help page
      print(
        "Usage: mixer_monitor [OPTION] [OPTION]...\n"..
        "-e                       Show machine energy information"..
        "-i                       Show machine item information"..
        "-o                       Runs script once to get info snapshot"..
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
  data.memUse = data.memCap - data.memFree
  data.memString =(
    "Watchdog Active | RAM: "..
    data.memUse.."/"
    ..data.memCap.." | "..
    tostring(math.floor((data.memUse / data.memCap)*100)).."%"
  )
  --auto-reboot
  if (data.memUse / data.memCap) > 0.95 then
    computer.shutdown(true)
  end
  return(data)
end

--Machine Data Acquisition
function getMachineData()
  local data={}
  data.energyStored = component.ie_mixer.getEnergyStored()
  data.maxEnergyStored = component.ie_mixer.getMaxEnergyStored()
  --Format quick reference percent string
  data.energyPercent = tostring(math.min((data.energyStored/data.maxEnergyStored)*100)).."%"
  data.fluidOutput = component.ie_mixer.getTank()
  data.activity = component.ie_mixer.isActive()
  data.validity = component.ie_mixer.isValidRecipe()
  --Creating Table of item inputs
  data.itemInputs = {}
  for i=1,12,1 do
    data.itemInputs[i] = component.ie_mixer.getInputStack(i)
    --creates data.itemInputs table of 12 itemStack tables, occupied slots include fields for:
    --damage, 
    --hasTag (Has NBT Data Attached), 
    --label(Current Name), 
    --maxDamage, 
    --maxProgress, 
    --maxSize(Stack Size), 
    --name(Item Ref), 
    --nameUnlocalized(Global Item / Tile Ref), 
    --progress, 
    --size (Actual Stack Count)
  end
  
end

--Main Loop
function runLoop()
  --Clear screen text buffer and prep with 
  local termBuffer =(
    meta.name..
    "\n" ..
    meta.version..
    " by "..
    meta.author..
    "\n"
  )
  --Call Watchdog and parse data
  watchdogData = watchdog()
  termBuffer = termBuffer .. watchdogData.memString .. "\n"
  
  --Read Machine Data and parse
  machineData = getMachineData()
  if OPTS.e==true then -- Check if energy info is enabled
    termBuffer =termBuffer .. "Energy: " .. machineData.energyStored .. "/" .. machineData.maxEnergyStored .. "(" .. machineData.energyPercent .. ")\n"
  end
  termBuffer =(termBuffer ..
  "Machine Active: "..machineData.activity.."\n"..
  "Recipe Valid: "..machineData.validity.."\n")
  if OPTS.i then termBuffer =(termBuffer .. "Item Inputs:\n") end
  if OPTS.i then -- Check if inventory info is enabled
    for i=1,12 do
      local itemData = machineData.itemInputs[i]
      if itemData.size ~= nil then
        termBuffer =(termBuffer..
          " Input "..i..": "..
          itemData.size.."x "..
          itemData.name)
          if itemData.hasTag then termBuffer =termBuffer.."(NBT)" end
          if itemData.maxDamage~=0 then termBuffer =(termBuffer.."(Dur:"..tostring(itemData.maxDamage - itemData.damage).."/"..itemData.maxDamage) end
          termBuffer =(termBuffer.."\n" .."Progress: "..itemData.Progress.."/"..itemData.maxProgress.."\n")
      end
    end
  end
  if not OPTS.o then termBuffer = termBuffer .. "Press Q to exit program\n" end
  term.write(termBuffer)
end

repeat
  runLoop()
  os.sleep(0.05)
until OPTS.o or keyboard.isKeyDown("q")

--OLD CODE

--getData

--Watchdog

--Monitoring

--ManageMachine

--MAIN PROCESS

