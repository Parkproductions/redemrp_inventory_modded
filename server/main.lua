RegisterServerEvent("player:getItems")
RegisterServerEvent("item:giveItem")
local invTable = {}
data = {}
local inventory = {}
data = inventory

AddEventHandler('redemrp_inventory:getData', function(cb)
    cb(data)
end)

AddEventHandler("player:getItems", function(target)
    local _source
    if target ~= nil then
        _source = target
    else
        _source = source
    end
    local check = false
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        --print(identifier)
        print("doing stuff")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                if target ~= nil then
                    TriggerClientEvent("gui:getItems", _source, k.inventory)
                else
                    TriggerClientEvent("gui:getOtherItems", _source, k.inventory)
                end
                TriggerClientEvent("item:LoadPickups", _source, Pickups)
                TriggerClientEvent("player:loadWeapons", _source)
                check = true
                print("LOAD OLD")
                break

            end
        end
        if check == false then
            print("LOAD NEW")
            MySQL.Async.fetchAll('SELECT * FROM user_inventory WHERE `identifier`=@identifier AND `charid`=@charid;', {identifier = identifier, charid = charid}, function(inventory)
                if inventory[1] ~= nil then
                    local inv = json.decode(inventory[1].items)
                    table.insert(invTable, {id = identifier, charid = charid , inventory = inv})
                    TriggerClientEvent("gui:getItems", _source, inv)
                    TriggerClientEvent("item:LoadPickups", _source, Pickups)
                    TriggerClientEvent("player:loadWeapons", _source)
                else
                    user.addMoney(100)
                    local test = {
                        ["water"] = 3,
                        ["bread"] = 3,
                    }
                    MySQL.Async.execute('INSERT INTO user_inventory (`identifier`, `charid`, `items`) VALUES (@identifier, @charid, @items);',
                        {
                            identifier = identifier,
                            charid = charid,
                            items = json.encode(test)
                        }, function(rowsChanged)
                        end)
                    table.insert(invTable, {id = identifier, charid = charid , inventory = test})
                    TriggerClientEvent("gui:getItems", _source, test)
                    TriggerClientEvent("item:LoadPickups", _source, Pickups)
                end
            end)
        end
    end)
    Wait(1000)
    TriggerEvent("player:getCrafting", _source)
end)

RegisterServerEvent("player:getlLocker")
AddEventHandler("player:getlLocker", function()
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        MySQL.Async.fetchAll('SELECT * FROM user_locker WHERE `identifier`=@identifier AND `charid`=@charid;', {identifier = identifier, charid = charid}, function(locker)
            if locker[1] ~= nil then
                local inv = json.decode(locker[1].items)
                TriggerClientEvent("gui:getOtherItems", _source, inv)
            else
                local inv = {}
                TriggerClientEvent("gui:getOtherItems", _source, inv)
            end



        end)
    end)
end)

RegisterServerEvent("player:SavelLocker")
AddEventHandler("player:SavelLocker", function(data ,item ,amount ,type , hash)
    local _source = source
    local eq = data
    local _item = item
    local _amount = amount
    local _type = type
	local _hash = hash
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        MySQL.Async.fetchAll('SELECT * FROM user_locker WHERE `identifier`=@identifier AND `charid`=@charid;', {identifier = identifier, charid = charid}, function(locker)
            if locker[1] ~= nil then
                MySQL.Async.execute('UPDATE user_locker SET items = @items WHERE identifier = @identifier AND charid = @charid', {
                    ['@identifier']  = identifier,
                    ['@charid']  = charid,
                    ['@items'] = json.encode(eq)
                }, function (rowsChanged)
                    if rowsChanged == 0 then
                        print(('user_inventory: Something went wrong saving locker %s!'):format(identifier .. ":" .. charid))
                    else
                        print("saved locker")
                    end
                end)
            else
                MySQL.Async.execute('INSERT INTO user_locker (`identifier`, `charid`, `items`) VALUES (@identifier, @charid, @items);',
                    {
                        identifier = identifier,
                        charid = charid,
                        items = json.encode(eq)
                    }, function(rowsChanged)
					            if rowsChanged == 0 then
                        print(('user_inventory: Something went wrong saving locker %s!'):format(identifier .. ":" .. charid))
                    else
                        print("saved locker")
                    end
                    end)
            end

        end)
    end)
    if _type == "delete" then
        inventory.delItem(_source , _item, _amount)
    elseif _type == "add" then
	print(_amount)
	print(_hash)
        inventory.addItem(_source , _item, _amount ,_hash)	
   end
    TriggerClientEvent('gui:ReloadMenu', _source)
end)



RegisterServerEvent("weapon:saveAmmo")
AddEventHandler("weapon:saveAmmo", function(data)
    local _data = data
    local _source = source
    TriggerEvent("player:savInvSv", _source, _data)
end)

RegisterServerEvent("player:savInvSv")
AddEventHandler('player:savInvSv', function(source, data)
    local _source = source
    local _data = data
    local eq
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        --print(identifier)
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                eq = k.inventory
                local liczba_itemow = 0
                for name,value in pairs(k.inventory) do
                    if name ~= nil then
                        liczba_itemow = liczba_itemow + 1
                    end
                    if liczba_itemow > 1 then
                        if value == 0 then
                            eq[name] = nil
                        end
                    end
                end
                if _data ~= nil then
                    eq = _data
                    k.inventory = _data
                end
                MySQL.Async.execute('UPDATE user_inventory SET items = @items WHERE identifier = @identifier AND charid = @charid', {
                    ['@identifier']  = identifier,
                    ['@charid']  = charid,
                    ['@items'] = json.encode(eq)
                }, function (rowsChanged)
                    if rowsChanged == 0 then
                        print(('user_inventory: Something went wrong saving %s!'):format(identifier .. ":" .. charid))
                    else
                        print("saved")
                    end
                end)

                break

            end
        end

    end)
end)


AddEventHandler("item:add", function(source, arg)
    local _source = source
    local name = tostring(arg[1])
    local amount = arg[2]
    local hash2 = arg[3]
    local hash
    if tonumber(hash2) == nil then
        hash = GetHashKey(hash2)
        print("poszlo")
    else
        hash = hash2
    end
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                --    print(name)
                print(hash)
                if hash == 1 then
                    if inventory.checkItem(_source, name) + amount <= inventory.checkLimit(_source,name) then
                        if k.inventory[name] ~= nil then
                            local val = invTable[i]["inventory"][name]
                            newVal = val + amount
                            print(val)
                            print(newVal)
                            invTable[i]["inventory"][name]= tonumber(newVal)
                        else
                            invTable[i]["inventory"][name]= tonumber(amount)
                        end
                    else
                        local drop = (inventory.checkItem(_source, name) + amount) - inventory.checkLimit(_source, name)
                        invTable[i]["inventory"][name]= tonumber(inventory.checkLimit(_source, name))
                        TriggerClientEvent('item:pickup',_source, name, drop , 1)
                    end
                else
                    invTable[i]["inventory"][name]= {tonumber(amount)  , hash}
                    TriggerClientEvent("player:giveWeapon", _source, tonumber(amount) , hash )
                end
                print("send shit")
                TriggerClientEvent("gui:getItems", _source, k.inventory)
                TriggerEvent("player:savInvSv", _source)
                TriggerEvent("player:getCrafting", _source)
                break
            end
        end

    end)
end)
AddEventHandler("item:delete", function(source, arg)
    local _source = source
    local name = tostring(arg[1])
    local amount = tonumber(arg[2])
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                if tonumber(invTable[i]["inventory"][name]) ~= nil then
                    local val = invTable[i]["inventory"][name]
                    newVal = val - amount
                    invTable[i]["inventory"][name]= tonumber(newVal)
                else
                    invTable[i]["inventory"][name]= nil
                    TriggerClientEvent("player:removeWeapon", _source, tonumber(amount) , hash )
                end
                TriggerClientEvent("gui:getItems", _source, k.inventory)
                TriggerEvent("player:savInvSv", _source)
                TriggerClientEvent('gui:ReloadMenu', _source)
                break end
        end
    end)
end)


RegisterServerEvent("item:onpickup")
AddEventHandler("item:onpickup", function(id)
    local _source = source
    local pickup  = Pickups[id]
    TriggerEvent("item:add", _source ,{pickup.name, pickup.amount ,pickup.hash})
    TriggerClientEvent("item:Sharepickup", -1, pickup.name, pickup.obj , pickup.amount, x, y, z, 2)
    TriggerClientEvent('item:removePickup', -1, pickup.obj)
    Pickups[id] = nil
    TriggerClientEvent('player:anim', _source)
    TriggerClientEvent('gui:ReloadMenu', _source)
end)



RegisterCommand('giveitem', function(source, args)
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                local item = args[1]
                local amount = args[2]
                local test = 1
                TriggerEvent("item:add", _source, {item, amount, test}, identifier , charid)
                print("add")
                TriggerClientEvent('gui:ReloadMenu', _source)
                break
            end
        end
    end)
end)

RegisterCommand('giveweapon', function(source, args)
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                local name = args[1]
                local WeaponHash = args[2]
                local Ammo = args[3]
                TriggerEvent("item:add", _source, {name ,Ammo, WeaponHash}, identifier , charid)
                print("add")
                TriggerClientEvent('gui:ReloadMenu', _source)
                break
            end
        end
    end)
end)

RegisterServerEvent("item:use")
AddEventHandler("item:use", function(val)
    local _source = source
    local name = val
    local amount = 1
    print("poszlo")

    TriggerEvent("RegisterUsableItem:"..name, _source)
    TriggerClientEvent("redemrp_notification:start", _source, "Item used: "..name, 3, "success")
    TriggerClientEvent('gui:ReloadMenu', _source)


end)



RegisterServerEvent("item:drop")
AddEventHandler("item:drop", function(val, amount , hash)
    local _source = source
    local value
    local _hash = 1
    _hash = hash
    local name = val

    value = inventory.checkItem(_source, name)
    if _hash == 1 then

        local all = value-amount
        if all >= 0 then
            TriggerClientEvent('item:pickup',_source, name, amount , 1)
            TriggerEvent("item:delete", _source, {name , amount})
        end

    else

        TriggerClientEvent('item:pickup',_source, name, amount , _hash)
        TriggerEvent("item:delete", _source, {name , amount})
    end
    TriggerClientEvent('gui:ReloadMenu', _source)

end)



RegisterServerEvent("item:take")
AddEventHandler("item:take", function(val, amount , hash ,target, search)
    local _source 
    local _target 
	if search  then
	   _source = target
     _target = source
	else
	   _source = source
     _target = target
	end
    local name
    local value
    local _hash = 1
    _hash = hash
    local name = val

    value = inventory.checkItem(_source, name)
    if _hash == 1 then
        local all = value-amount
        print(all)
        if all >= 0 then
            TriggerEvent("item:delete", _target, {name , amount})
            Wait(500)

            TriggerEvent("item:add", _source ,{name, amount ,_hash})
        end

    else
        TriggerEvent("item:delete", _target, {name , amount})
        TriggerClientEvent("player:removeWeapon", _target ,amount, _hash)
        Wait(500)
        TriggerEvent("item:add", _source ,{name, amount ,_hash})
        TriggerClientEvent("player:giveWeapon", _source ,amount, _hash)
    end
    TriggerClientEvent('gui:ReloadMenu', _source)
    TriggerClientEvent('gui:ReloadMenu', _target)

end)


RegisterServerEvent("item:SharePickupServer")
AddEventHandler("item:SharePickupServer", function(name, obj , amount, x, y, z , hash)
    TriggerClientEvent("item:Sharepickup", -1, name, obj , amount, x, y, z, 1, hash)
    print("poszlo server")
    Pickups[obj] = {
        name = name,
        obj = obj,
        amount = amount,
        hash = hash,
        inRange = false,
        coords = {x = x, y = y, z = z}
    }
end)

RegisterServerEvent("test_lols")
AddEventHandler("test_lols", function(name, amount , target ,hash)
    local _target = target
    local _source = source
    local _name = name
    local _amount = amount
    local all
    if hash == 1 then
        local value = inventory.checkItem(_source, name)
        all = value-amount
    else
        all = amount
    end
    if all >= 0 then
        TriggerEvent("item:delete",_source, { name , amount})
        TriggerEvent('test_lols222', _target , name , amount ,hash)
        TriggerClientEvent('gui:ReloadMenu', _source)
        local DisplayName2 =  name
        if hash == 1 then
            if Config.Labels[name] ~= nil then
                DisplayName2 = Config.Labels[name]
            end
        else
            DisplayName2 = GetLabelTextByHash(hash)
        end
        TriggerClientEvent("pNotify:SendNotification",_source, {
            text = "<img src='nui://redemrp_inventory/html/img/items/"..name..".png' height='40' width='40' style='float:left; margin-bottom:10px; margin-left:20px;' />You have given: ".. DisplayName2.."<br>-"..tonumber(amount).."<br>to "..GetPlayerName(_target),
            type = "success",
            timeout = math.random(2000, 3000),
            layout = "centerRight",
            queue = "right"
        })
        TriggerClientEvent("pNotify:SendNotification",_target, {
            text = "<img src='nui://redemrp_inventory/html/img/items/"..name..".png' height='40' width='40' style='float:left; margin-bottom:10px; margin-left:20px;' />You've received: ".. DisplayName2.."<br>+"..tonumber(amount).."<br>to "..GetPlayerName(_source),
            type = "success",
            timeout = math.random(2000, 3000),
            layout = "centerRight",
            queue = "right"
        })

    else
        print("nie ma przedmiotu")
    end



end)


RegisterServerEvent("test_lols222")
AddEventHandler("test_lols222", function(source, name, amount, hash)
    local _source = source
    local _name = name
    local _amount = amount
    local _hash = hash
    TriggerEvent("item:add",_source, {name, amount, _hash})
    if _hash ~= 1 then
        TriggerClientEvent("player:giveWeapon", _source, tonumber(amount) , _hash)
    end
    TriggerClientEvent('gui:ReloadMenu', _source)
end)

function checkItem(_source, name)
    local value = 0
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        for i,k in pairs(invTable) do
            if k.id == identifier and k.charid == charid then
                value = invTable[i]["inventory"][name]

                if tonumber(value) == nil then
                    value = 0

                end
                break
            end
        end
    end)
    return tonumber(value)
end

function inventory.checkItem(_source, name)
    local  value = checkItem(_source, name)
    return tonumber(value)
end

function inventory.checkLimit(_source, name)
    local value = 64
    if Config.Limit[name] ~= nil then
        value = Config.Limit[name]
    end
    return tonumber(value)
end

function inventory.addItem(_source, name , amount ,hash)
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        if hash == nil or hash == 0 then
            local test = 1
            TriggerEvent("item:add", _source ,{name, amount , test})
        else
            TriggerEvent("item:add", _source ,{name, amount , hash})
        end
    end)
end

function inventory.delItem(_source, name , amount)
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")

        TriggerEvent("item:delete", _source, {name , amount})
    end)
end

RegisterServerEvent("redemrp_inventory:deleteInv")
AddEventHandler("redemrp_inventory:deleteInv", function(charid, Callback)
    local _source = source
    local id
    for k,v in ipairs(GetPlayerIdentifiers(_source))do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            id = v
            break
        end
    end
    for i,k in pairs(invTable) do
        if k.id == id and k.charid == charid then
            table.remove(invTable , i)
        end
    end
    local Callback = callback
    MySQL.Async.fetchAll('DELETE FROM user_inventory WHERE `identifier`=@identifier AND `charid`=@charid;', {identifier = id, charid = charid}, function(result)
        if result then
        else
        end
    end)
end)

--------EXAMPLE---------Register Usable item---------------EXAMPLE
RegisterServerEvent("RegisterUsableItem:wood")
AddEventHandler("RegisterUsableItem:wood", function(source)
    print("test")
end)
------------------------EXAMPLE----------------------------EXAMPLE


