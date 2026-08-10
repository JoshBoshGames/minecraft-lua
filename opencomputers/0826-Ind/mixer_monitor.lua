-- Program Information
meta={}
  meta.name = "Immersive Engineering Mixer Control"
  meta.author = "JoshBoshGames"
  meta.version = "v0.2.0"
  meta.view_url = "https://github.com/JoshBoshGames/minecraft-lua/blob/main/opencomputers/0826-Ind/mixer_monitor.lua"
  meta.raw_update_url = "https://raw.githubusercontent.com/JoshBoshGames/minecraft-lua/refs/heads/main/opencomputers/0826-Ind/mixer_monitor.lua"

--Initialisation
  --Acquire/Provide meta info
    shell = require("shell")
    sides = require("sides")
    ARGS, OPTS = shell.parse(...) --Pulls CLI options and arguments
  --Mode Switching
    mode={}
    mode.activity = sides[OPTS.activity_side]~=nil
    mode.validity = sides[OPTS.validity_side]~=nil
    mode.enable = sides[OPTS.enable_side]~=nil
    mode.empty = sides[OPTS.empty_side]~=nil
    mode.ingredientCount = (sides[OPTS.ingredient_side]~nil and OPTS.key_ingredient~=nil)
    if mode.ingredientCount then keyIngredientQuantity=0 end
    if OPTS.help==true then --Help page
      print(
        "Usage: mixer_monitor [OPTION] [OPTION]...\n"..
        "-e                         Show machine energy information\n"..
        "-i                         Show machine item information\n"..
        "-l                         Show machine fluid information\n"..
        "-o                         Runs script once to get info snapshot\n"..
        "--activity_side=[SIDE]     Set the activity reporting side for redstone out\n"..
        "--validity_side=[SIDE]     Set the valid_recipe reporting side for redstone out\n"..
        "--enable_side=[SIDE]       Set the redstone machine_enable side for redstone in\n"..
        "--empty_side=[SIDE]        Set the empty items reporting side for redstone out\n"..
        "--key_ingredient=[REF]     Set the key ingredient to look for and monitor\n"..
        "--ingredient_side=[SIDE]   Set the ingredient count monitor side for redstone output\n"..
        "--help                     Show this message and then close\n"
      )
      os.exit()
    else
        print(
          "Program running in standard mode... "..
          "For more information, run: mixer_monitor --help"
        )
        os.sleep(1)
    end  
  
  --Library Requisition
    os = require("os")
    component = require("component")
    computer = require("computer")
    term = require("term")
    redstone = component.redstone
    keyboard= require("keyboard")
    mixer = component.ie_mixer
    

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
  data.energyStored = mixer.getEnergyStored()
  data.maxEnergyStored = mixer.getMaxEnergyStored()
  --Format quick reference percent string
  data.energyPercent = tostring(math.min((data.energyStored/data.maxEnergyStored)*100)).."%"
  data.fluidOutput = mixer.getTank()
  data.activity = mixer.isActive()
  data.validity = mixer.isValidRecipe()
  --Creating Table of item inputs
  data.itemInputs = {}
  for i=1,8 do
    data.itemInputs[i] = mixer.getInputStack(i)
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
  return(data)
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
  "Machine Active: "..tostring(machineData.activity).."\n"..
  "Recipe Valid: "..tostring(machineData.validity).."\n")
  if OPTS.i then -- Check if inventory info is enabled
    termBuffer =(termBuffer .. "Item Inputs:\n") 
    for i=1,8 do
      local itemData = machineData.itemInputs[i]
      if itemData.size ~= nil then
        termBuffer =(termBuffer..
          " Input "..i..": "..
          itemData.size.."x "..
          itemData.label.." "..
          itemData.name)
          if itemData.hasTag then termBuffer =termBuffer.."(NBT)" end
          if itemData.maxDamage~=0 then termBuffer =(termBuffer.."(Dur:"..tostring(itemData.maxDamage - itemData.damage).."/"..itemData.maxDamage) end
          termBuffer =(termBuffer.."\n" .."Progress: "..itemData.progress.."/"..itemData.maxProgress.."\n")
      end
    end
  end
  if OPTS.l then -- Check if fluid info is enabled
    termBuffer =(termBuffer .. "Fluid Output:\n "..
    tostring(machineData.fluidOutput.amount).."mB x "..
    tostring(machineData.fluidOutput.label)..
    " ("..tostring(machineData.fluidOutput.name)..")\n")
  end
  if mode.activity then
    local rsTable={[true]=15,[false]=0}
    redstone.setOutput(sides[OPTS.activity_side],rsTable[machineData.activity])
  end
  if mode.validity then
    local rsTable={[true]=15,[false]=0}
    redstone.setOutput(sides[OPTS.validity_side],rsTable[machineData.validity])
  end
  if mode.enable then
    mixer.enableComputerControl(true)
    mixer.setEnabled(redstone.getInput(side[OPTS.enable_side])>0)
    mixer.enableComputerControl(false)
  end
  if mode.empty then
    local rsTable={[true]=15,[false]=0}
    dataEmpty = false
    for i=1,8 do
      local itemData=machineData.itemInputs[i]
      dataEmpty = dataEmpty or itemData.size~=nil
    end
    redstone.setOutput(sides[OPTS.empty_side], rsTable[dataEmpty])
  end
  if mode.ingredientCount then
    local ingredientDeplete = false
    local rsTable={[true]=15,[false]=0}
      for i=1,8 do
        local itemData=machineData.itemInputs[i]
        if itemData.name==OPTS.key_ingredient then
          redstone.setOutput(sides[OPTS.ingredient_side],rsTable[itemData.size < keyIngredientQuantity]
          keyIngredientQuantity=itemData.Size[]
        end
      end
  end
  
  if not OPTS.o then termBuffer = termBuffer .. "Press Q to exit program\n" end
  term.clear()
  term.write(termBuffer)
  os.sleep(0.05)
end

 repeat
  local success, err = pcall(runLoop)
  if not success then
    print("Unrecoverable Error: \n"..tostring(err))
    computer.beep(50,5)
  end
 until OPTS.o or keyboard.isKeyDown("q") or not success


print("Disconnect Computer Control")
mixer.enableComputerControl(false)