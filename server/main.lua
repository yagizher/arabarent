ESX             = nil
local ShopItems = {}
local hasSqlRun = false

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Load items
AddEventHandler('onMySQLReady', function()
	hasSqlRun = true
	LoadShop()
end)

-- extremely useful when restarting script mid-game
Citizen.CreateThread(function()
	Citizen.Wait(2000) -- hopefully enough for connection to the SQL server

	if not hasSqlRun then
		LoadShop()
		hasSqlRun = true
	end
end)

function LoadShop()
	local shopResult = MySQL.Sync.fetchAll('SELECT * FROM rentable')

	for i=1, #shopResult, 1 do
		if ShopItems[shopResult[i].store] == nil then
			ShopItems[shopResult[i].store] = {}
		end
	
		table.insert(ShopItems[shopResult[i].store], {
			label = shopResult[i].label,
			item  = shopResult[i].item,
			price = shopResult[i].price,
		})
	end
end

ESX.RegisterServerCallback('Unknownlifecarrent:requestDBItems', function(source, cb)
	if not hasSqlRun then
		TriggerClientEvent('esx:showNotification', source, 'The shop database has not been loaded yet, try again in a few moments.')
	end

	cb(ShopItems)
end)

RegisterServerEvent('Unknownlifecarrent:buyItem')
AddEventHandler('Unknownlifecarrent:buyItem', function(itemName, zone)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	-- get price
	local price = 0

	for i=1, #ShopItems[zone], 1 do
		if ShopItems[zone][i].item == itemName then
			price = ShopItems[zone][i].price
			itemLabel = ShopItems[zone][i].label
			break
		end
	end


	if xPlayer.getMoney() >= price then
		xPlayer.removeMoney(price)
	else
		local missingMoney = price - xPlayer.getMoney()
		ESX.ShowNotification(_source, 'Du hast nicht genug Geld!')
	end
end)

ESX.RegisterServerCallback('Unknownlifecarrent:hasEnoughMoney', function(source, cb, itemName, zone)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	-- get price
	local price = 0

	for i=1, #ShopItems[zone], 1 do
		if ShopItems[zone][i].item == itemName then
			price = ShopItems[zone][i].price
			itemLabel = ShopItems[zone][i].label
			break
		end
	end


	if xPlayer.getMoney() >= price then
		cb(true)
	else
		cb(false)
	end
end)