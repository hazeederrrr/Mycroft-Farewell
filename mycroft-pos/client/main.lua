local Positions = {}

RegisterNetEvent("mycroft-pos:RefreshPositions", function(data)
  Positions = data
  CreateZones()
end)

function OpenShopMenu(Position)
  local Pos = Positions[Position]
  local elements = {{unselectable = true,icon ="fa-solid fa-cash-register", title = "Current Paying For: "..Pos.StoreName, description = "total price: "..Pos.Price, name = "total", price = 0},
  {title = "Pay Via Cash",icon = "fa-solid fa-wallet",disabled = Pos.Price < 1,description = "", name = "cash"},
  {title = "Pay Via Card",icon = "fa-solid fa-credit-card",disabled = Pos.Price < 1, description = "", name = "card"}
}
  ESX.OpenContext("right", elements, function(menu, data)
    if data.name == "cash" then
      ESX.TriggerServerCallback('mycroft-pos:PayWallet', function(success)
        if success then
          ESX.CloseContext()
          ESX.ShowNotification("Successfully Paid!", "success")
        else
          ESX.ShowNotification("You do not have enough money", "error")
        end
      end, Position)
    elseif data.name == "card" then
      ESX.TriggerServerCallback('mycroft-pos:PayCard', function(success)
        if success then
          ESX.CloseContext()
          ESX.ShowNotification("Successfully Paid!", "success")
        else
          ESX.ShowNotification("You do not have enough money", "error")
        end
      end, Position)
    end
  end)
end

function ManagePositions()
  local elements = {{unselectable = true, title = "Manage Positions.", description = "Click to remove a position", icon = "fa-solid fa-cash-register"}}
  for k,v in pairs(Positions) do
    elements[#elements + 1] = {title = v.StoreName, description = "Click to remove this position", icon = "fa-solid fa-cash-register", index = k}
  end
  ESX.OpenContext("right", elements, function(menu, data)
    if data.index then
      ESX.TriggerServerCallback("mycroft-pos:RemovePoS", function(success)
        if success then
          ESX.CloseContext()
          ESX.ShowNotification("Successfully Removed!", "success")
        else
          ESX.ShowNotification("You do not have permission to do this!", "error")
        end
      end, data.index)
    end
  end)
end

function OpenManageMenu(Position)
  local Pos = Positions[Position]
  local elements = {{unselectable = true, title = "Managing: "..Pos.StoreName}, {title = "Add Item", value = "additem"}}
  for i = 1, #Pos.Inventory do
    elements[#elements + 1] = {title = Pos.Inventory[i].name,value = i, icon = "fa-solid fa-trash", description = "Price: £"..Pos.Inventory[i].price, index = "removeitem"}
  end
  ESX.OpenContext("right", elements, function(menu, data)
    if data.value == "additem" then
      elements = {{unselectable = true, title = "Add New Item", icon = "fa-solid fa-plus"}, 
      {title = "Item Name", input = true,icon = "fa-solid fa-signature", inputType = "text", inputValue = "", inputPlaceholder = ""},
      {title = "Item Price", input = true,icon = "fa-solid fa-sack-dollar", inputType = "number",inputMin = 1, inputMax = 10000000, inputValue = 1, inputPlaceholder = ""},
      {title = "Add Item", icon = "fa-solid fa-plus", description = "Add Job To List.", index = "confirm"},
      {title = "Return", icon = "fa", description = "return to Job List.", index = "return"}}
      ESX.RefreshContext(elements)
    end
    if data.index == "removeitem" then
      ESX.TriggerServerCallback('mycroft-pos:RemoveItem', function(success)
        if success then
          ESX.CloseContext()
          ESX.ShowNotification("Successfully Removed Item!", "success")
        else
          ESX.ShowNotification("Failed To Remove Item!", "error")
        end
      end, Position, data.value)
    end
    if data.index == "return" then
      OpenManageMenu(Position)
    end
    if data.index == "confirm" then
      local Data = {}
      Data.name = menu.eles[2].inputValue
      Data.price = menu.eles[3].inputValue
      ESX.TriggerServerCallback("mycroft-pos:AddItem", function(success)
        if success then
          ESX.ShowNotification("Item Added", "success")
          OpenManageMenu(Position)
        else
          ESX.ShowNotification("Failed To Add Item")
        end
      end, Position, Data)
    end
  end)
end

AddEventHandler('mycroft-pos:onInteract',function(targetData,itemData)
  if itemData.name == "open_shop" then
    OpenShopMenu(targetData.vars.Zone)
  end
  if itemData.name == "manage_shop" then
    ESX.TriggerServerCallback("mycroft-pos:CanAccessPos", function(success)
      if success then
        OpenManageMenu(targetData.vars.Zone)
      else
        ESX.ShowNotification("You Do Not Have Access To This Pos")
      end
    end, targetData.vars.Zone)
  end
end)

local Zones = {}

function CreateZones()
  for i=1, #Zones do
    target.removeTarget(Zones[i])
  end
  for i=1, #Positions do
    local Pos = vector3(Positions[i].BuyZone.pos.x, Positions[i].BuyZone.pos.y, Positions[i].BuyZone.pos.z)
    local Targ = target.addPoint("mycroft-pos:BuyZone:"..i, Positions[i].StoreName, 'fa-solid fa-store', Pos, 3.0, 'mycroft-pos:onInteract', {
      {
        name = 'open_shop',
        label = 'Open Til'
      },
      {
        name = 'manage_shop',
        label = 'Manage Tils'
      }
    },{
      Zone = i
    })
    Zones[#Zones+1] = "mycroft-pos:BuyZone:"..i
  end
end


function ManageJobs(data)
  local Elements = {{unselectable = true, title = "Allowed Jobs."},{title = "Return", icon = "fas fa-arrow-left", description = "return to Job List.", index = "return1"}, {title = "Add New",icon = "fa-solid fa-plus", description = "Add a new job to the list."}}
  local CurrentJobs = data[5].data
  for i = 1, #CurrentJobs do
    Elements[#Elements + 1] = {title = CurrentJobs[i],index = i, icon = "fa-solid fa-trash", description = "Remove this job from the list.", value = CurrentJobs[i]}
  end

  ESX.OpenContext("right", Elements, function(menu, dataa)
    if dataa.value then
      table.remove(data[5].data, data.index)
      ManageJobs(data)
    elseif dataa.title == "Add New" then
      local Elements = {{unselectable = true, title = "Add New Job", icon = "fa-solid fa-plus"}, 
      {title = "Job Name", input = true,icon = "fa-solid fa-signature", inputType = "text", inputValue = "", inputPlaceholder = ""},
      {title = "Add Job", icon = "fa-solid fa-plus", description = "Add Job To List.", index = "confirm"},
      {title = "Return", icon = "fas fa-arrow-left", description = "return to Job List.", index = "return"}}
      ESX.RefreshContext(Elements)
    elseif dataa.index == "return" then
      ESX.CloseContext()
      ManageJobs(data)
    elseif dataa.index == "return1" then
      ESX.CloseContext()
      CreatePoS(data)
    elseif dataa.index == "confirm" then
      ESX.CloseContext()
      local NewJob = menu.eles[2].inputValue
      if NewJob ~= "" then
        data[5].data[#data[5].data + 1] = NewJob
        ManageJobs(data)
      end
    end
  end)
end



function CreatePoS(data)
  local Data = {}
  local Elements = data or {
    {unselectable = true, title = 'Create A Store.', icon = 'fa-solid fa-store'},
    {title = "Name", input = true,icon = "fa-solid fa-signature", inputType = "text", inputValue = "", inputPlaceholder = "Store Name", name = "setName"},
    {title = "Society", input = true,icon = "fa-solid fa-signature", inputType = "text", inputValue = "", inputPlaceholder = "name", name = "setSociety"},
    {title = 'Set Buy Zone.', icon = 'fa-solid fa-box-open', description = 'Set the Customer Buy Zone.', value = 'setBuyZone', data = {}},
    {title = 'Job Management.', icon = "fa-solid fa-users", description = 'Manage Which Jobs Can Access The Store.', value = 'setJobs', data = {}},
    {title = 'Create.', icon = 'fa-solid fa-check', description = 'Create Store With Current Settings.', value = 'create'},
  }
  ESX.OpenContext("right", Elements, function(menu, Option)
    if menu.eles[2] and menu.eles[2].inputValue and menu.eles[1].title == 'Create A Store.' then
      Elements[2].inputValue = menu.eles[2].inputValue
    end
    if menu.eles[3] and menu.eles[3].inputValue and menu.eles[1].title == 'Create A Store.' then
      Elements[3].inputValue = menu.eles[3].inputValue
    end
    if Option.value == "setBuyZone" then
      ESX.CloseContext()
      ESX.TextUI("Press ~b~[E]~s~ To Set Buy Position")
      while true do
        Wait(0)
        if IsControlJustPressed(0, 38) then
          local PlayerPos = GetEntityCoords(ESX.PlayerData.ped)
          Elements[4].data.pos = GetEntityCoords(ESX.PlayerData.ped)
          Elements[4].data.heading = GetEntityHeading(ESX.PlayerData.ped)
          Elements[4].description = 'Pos: '.. ESX.Round(PlayerPos.x, 1)..', '.. ESX.Round(PlayerPos.y, 1)..', '..ESX.Round(PlayerPos.z, 1)
          ESX.HideUI()
          CreatePoS(Elements)
          break
        end
      end
    end
    if Option.value == "setJobs" then 
      ESX.CloseContext()
      ManageJobs(Elements)
    end
    if Option.value == "create" then
      local Data = {}
      Data.name = Elements[2].inputValue
      Data.society = Elements[3].inputValue
      Data.BuyZone = Elements[4].data
      Data.JobManagement = Elements[5].data
      ESX.TriggerServerCallback("mycroft-pos:CreatePoS", function()
        ESX.CloseContext()
        ESX.ShowNotification("Store Created.", "success")
      end, Data)
    end
  end)
end

RegisterCommand('pos:create', function()
  CreatePoS()
end, true)

RegisterCommand('pos:remove', function()
  ManagePositions()
end, true)