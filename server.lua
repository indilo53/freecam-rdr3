RegisterCommand('freecam', function(source, args)
	if source ~= 0 then
		TriggerClientEvent('freecam:toggle', source)
	end
end)

RegisterCommand('pos', function(source, args)
	if source ~= 0 then
		TriggerClientEvent('freecam:pos', source)
	end
end)
