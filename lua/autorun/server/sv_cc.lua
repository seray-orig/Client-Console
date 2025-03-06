util.AddNetworkString("SendCMDToClient_CC")			-- Всем клиентам суперадминам отправляется отчёт кто какой запрос отправил
util.AddNetworkString("QueryCMDToServer_CC")		-- Серверу с клиента отправляется запрос на вполнение команды
util.AddNetworkString("SendLuaErrorToClient_CC")	-- Всем клиентам суперадминам отправляются сообщения о Lua ошибках (если они есть)

hook.Add("OnLuaError", "LuaErrorCallBack", function (err)
	for _, ply in ipairs(player.GetAll()) do
        if ply:IsSuperAdmin() then
			net.Start("SendLuaErrorToClient_CC")	-- На случай вызова хука отправляем сообщение об ошибке
			net.WriteString(err)
			net.Send(ply)
		end
	end
end)

net.Receive("QueryCMDToServer_CC", function(len, ply)
	if not ply:IsSuperAdmin() then return false end		-- Если каким-то образом не суперадмин отправит запрос, то сервер его не выполнит

	local cmd = net.ReadString()	-- Команда отправленная клиентом

	local function send()
		for _, ply in ipairs(player.GetAll()) do
			if ply:IsSuperAdmin() then
				net.Start("SendCMDToClient_CC")		-- Отправка клиентам суперадминам отчёт о текущем запросе
				net.WriteString(ply:Name())
				net.WriteString(cmd)
				net.Send(ply)
			end
		end
		print("[client console] " .. ply:Name() .. ": " .. cmd)	-- Отчёт для серверной консоли
	end

	if IsConCommandBlocked(cmd) and (not string.StartsWith(cmd, "_restart") or not string.StartsWith(cmd, "load")) then		-- Если команда заблокирована (из списка IsConCommandBlocked для game.ConsoleCommand доступны только две команды "_restart" и "load")
		cmd = cmd .. "\ngame.ConsoleCommand blocked! (" .. string.Split(cmd, " ")[1] .. ")"		-- В исходный запрос добавляется вторая строка с сообщением об ошибке
		send()
	else
		send()
		game.ConsoleCommand(cmd .. "\n")	-- Запуск команды если всё ок
	end

end)