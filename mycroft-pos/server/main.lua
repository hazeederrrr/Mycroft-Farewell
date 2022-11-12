local Positions = {}

function PointsRefresh()
  Positions = {}
  local PositionsList = LoadResourceFile(GetCurrentResourceName(), 'points.json')
  if PositionsList then
    -- Positions = json.decode(PositionsList
    for i = 1, #Positions do
      Positions[i].Inventory = {}
      Positions[i].Price = 0
    end
    TriggerClientEvent("mycroft-pos:RefreshPositions", -1, Positions)
  else
    Positions = {}
    print("[^1ERROR^7]: ^5points.json^7 Not Found!")
  end
end

CreateThread(function()
  PointsRefresh()
end)

AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
  Wait(1000)
  TriggerClientEvent("esx_property:syncProperties", playerId, Positions)
end)

function SavePoints()
    if Positions then
      SaveResourceFile(GetCurrentResourceName(), 'points.json', json.encode(Positions))
    end
end

function IsJob(Player, Jobs)
  --print(Player)
  local xPlayer = ESX.GetPlayerFromId(Player)
  for i=1, #Jobs do
    if xPlayer.job.name == Jobs[i] then
      return true
    end
  end
  return false
end

ESX.RegisterServerCallback("mycroft-pos:GetItems", function(source, cb, Pos)
  local xPlayer = ESX.GetPlayerFromId(source)
  local PlayerPed = GetPlayerPed(source)
  local PlayerCoords = GetEntityCoords(PlayerPed)
  local AttemptedPos = Positions[Pos]
  local Distance = #(PlayerCoords - vector3(AttemptedPos.BuyZone.pos.x, AttemptedPos.BuyZone.pos.y, AttemptedPos.BuyZone.pos.z))

  if Distance <= 3.0 then
      cb(AttemptedPos)
  else
    cb(false)
  end
end)

ESX.RegisterServerCallback("mycroft-pos:PayWallet", function(source, cb, Pos)
  local xPlayer = ESX.GetPlayerFromId(source)
  local PlayerPed = GetPlayerPed(source)
  local PlayerCoords = GetEntityCoords(PlayerPed)
  local AttemptedPos = Positions[Pos]
  local Distance = #(PlayerCoords - vector3(AttemptedPos.BuyZone.pos.x, AttemptedPos.BuyZone.pos.y, AttemptedPos.BuyZone.pos.z))

  if Distance <= 3.0 then
    if AttemptedPos.Price > 0 then
      if xPlayer.getMoney() >= AttemptedPos.Price then
        TriggerEvent('esx_society:getSociety',AttemptedPos.society, function(society)
          if society then -- verified society
            TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                xPlayer.removeMoney(AttemptedPos.Price)
                xPlayer.addInventoryItem("receipt", 1,100, {["price"] = AttemptedPos.Price, ["store"] = AttemptedPos.StoreName, date = os.date("%d/%m/%Y %X"), ["Payment Method"] = "Cash"})
                Positions[Pos].Price = 0
                Positions[Pos].Inventory = {}
                TriggerClientEvent("mycroft-pos:RefreshPositions", -1, Positions)
                account.addMoney(AttemptedPos.Price)
                cb(true)
            end)
          end
        end)
      else
        cb(false)
      end
    end
  else
    cb(false)
  end
end)

ESX.RegisterServerCallback("mycroft-pos:PayCard", function(source, cb, Pos)
  local xPlayer = ESX.GetPlayerFromId(source)
  local PlayerPed = GetPlayerPed(source)
  local PlayerCoords = GetEntityCoords(PlayerPed)
  local AttemptedPos = Positions[Pos]
  local Distance = #(PlayerCoords - vector3(AttemptedPos.BuyZone.pos.x, AttemptedPos.BuyZone.pos.y, AttemptedPos.BuyZone.pos.z))

  if Distance <= 3.0 then
    if AttemptedPos.Price >= 0 then
      if xPlayer.getAccount("bank").money >= AttemptedPos.Price then
        TriggerEvent('esx_society:getSociety',AttemptedPos.society, function(society)
          if society then -- verified society
            TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                xPlayer.removeAccountMoney("bank", AttemptedPos.Price)
                xPlayer.addInventoryItem("receipt", 1,100, {["price"] = AttemptedPos.Price, ["store"] = AttemptedPos.StoreName, date = os.date("%d/%m/%Y %X"), ["Payment Method"] = "Card"})
                Positions[Pos].Price = 0
                Positions[Pos].Inventory = {}
                TriggerClientEvent("mycroft-pos:RefreshPositions", -1, Positions)
                account.addMoney(AttemptedPos.Price)
                cb(true)
            end)
          end
        end)
      else
        cb(false)
      end
    end
  else
    cb(false)
  end
end)

ESX.RegisterServerCallback("mycroft-pos:AddItem", function(source, cb, Pos, Data)
  local xPlayer = ESX.GetPlayerFromId(source)
  local PlayerPed = GetPlayerPed(source)
  local PlayerCoords = GetEntityCoords(PlayerPed)
  local AttemptedPos = Positions[Pos]
  local Distance = #(PlayerCoords - vector3(AttemptedPos.BuyZone.pos.x, AttemptedPos.BuyZone.pos.y, AttemptedPos.BuyZone.pos.z))
  local IsJob = IsJob(source, AttemptedPos.JobManagement)
  if Distance <= 3.0 then
    if IsJob then
        Positions[Pos].Inventory[#Positions[Pos].Inventory + 1] = {price = Data.price, name = Data.name}
        Positions[Pos].Price += Data.price
        TriggerClientEvent("mycroft-pos:RefreshPositions", -1, Positions)
        cb(true)
      else 
        cb(false)
      end
    else
      cb(false)
    end
end)

ESX.RegisterServerCallback("mycroft-pos:RemoveItem", function(source, cb, Pos, Index)
  local xPlayer = ESX.GetPlayerFromId(source)
  local PlayerPed = GetPlayerPed(source)
  local PlayerCoords = GetEntityCoords(PlayerPed)
  local AttemptedPos = Positions[Pos]
  local Distance = #(PlayerCoords - vector3(AttemptedPos.BuyZone.pos.x, AttemptedPos.BuyZone.pos.y, AttemptedPos.BuyZone.pos.z))
  local IsJob = IsJob(source, AttemptedPos.JobManagement)
  if Distance <= 3.0 then
    if IsJob then
      local Item = Positions[Pos].Inventory[Index]
      Positions[Pos].Price -= Item.price
      table.remove(Positions[Pos].Inventory, Index)
      TriggerClientEvent("mycroft-pos:RefreshPositions", -1, Positions)
      cb(true)
      else 
        cb(false)
      end
    else
      cb(false)
    end
end)


ESX.RegisterServerCallback("mycroft-pos:CanAccessPos", function(source, cb, Pos)
  local xPlayer = ESX.GetPlayerFromId(source)
  local PlayerPed = GetPlayerPed(source)
  local PlayerCoords = GetEntityCoords(PlayerPed)
  local AttemptedPos = Positions[Pos]
  local Distance = #(PlayerCoords - vector3(AttemptedPos.BuyZone.pos.x, AttemptedPos.BuyZone.pos.y, AttemptedPos.BuyZone.pos.z))
  local IsJob = IsJob(source, AttemptedPos.JobManagement)
  if Distance <= 3.0 then
    if IsJob then
      cb(true)
    else
      cb(false)
    end
  else
    cb(false)
  end
end)

ESX.RegisterServerCallback("mycroft-pos:CreatePoS", function(source, cb, data)
  local xPlayer = ESX.GetPlayerFromId(source)
  if xPlayer.getGroup() == "admin" then
    local Data = {}
    Data.StoreName = data.name
    Data.society = data.society
    Data.BuyZone = data.BuyZone
    Data.JobManagement = data.JobManagement
    Data.Inventory = {}
    Data.Price = 0
    Positions[#Positions + 1] = Data
    cb(true)
    TriggerClientEvent("mycroft-pos:RefreshPositions", -1, Positions)
    SavePoints()
  else
    cb(false)
  end
end)

ESX.RegisterServerCallback("mycroft-pos:RemovePoS", function(source, cb, index)
  local xPlayer = ESX.GetPlayerFromId(source)
  if xPlayer.getGroup() == "admin" then
    table.remove(Positions, index)
    cb(true)
    TriggerClientEvent("mycroft-pos:RefreshPositions", -1, Positions)
    SavePoints()
  else
    cb(false)
  end
end)