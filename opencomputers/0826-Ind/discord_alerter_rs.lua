-- Program Information
meta={
  name="Discord Alerter Microcontroller - Redstone Trigger",
  author="JoshBoshGames",
  version="v0.0.1",
  view_url="https://github.com/JoshBoshGames/minecraft-lua/blob/main/opencomputers/0826-Ind/discord_alerter_rs.lua",
  raw_update_url="https://raw.githubusercontent.com/JoshBoshGames/minecraft-lua/refs/heads/main/opencomputers/0826-Ind/discord_alerter_rs.lua"
}

-- Program constants
constant={
  discord_url="*INSERT_WEBHOOK_URL_HERE*",  -- Setting discord URL to enable webhook use
  message="*INSERT_ALERT_MESSAGE_HERE*"  -- Setting Alert Message to send to discord
}

-- Loading Libraries and 'Hardware' hooks
component = require("component")
computer = require("computer")
internet = component.proxy(component.list("internet")())

-- Program main loop
while true do
  repeat
    new_signal = table.pack(computer.pullSignal())  -- Pull new events
  until new_signal[1] == "redstone_changed"  --Filtering specifically redstone events
  -- creating reference table for redstone event information
  rs_signal={}
  rs_signal.card_address = new_signal[2]
  rs_signal.side = new_signal[3]
  rs_signal.old_strength = new_signal[4]
  rs_signal.new_strength = new_signal[5]
  
  if rs_signal.old_strength == 0 and rs_signal.new_strength ~= 0 then -- Test if change relates to redstone activation
    -- Activate webhook
    payload = '{"content": "' .. constant.message .. '"}'
    headers = {
      ["Content-Type"] = "application/json"
    }
    request, err = internet.request(constant.discord_url, payload, headers, "POST")
    if table.pack(request.response())[1] == 200 then
      computer.beep(200,0.1) computer.beep(250,0.1) computer.beep(300,0.1) computer.beep(400,0.1) -- Send Success SFX
    else
      computer.beep(125,1) -- Send Fail SFX
    end
  end
end
