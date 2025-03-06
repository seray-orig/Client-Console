local mainBackgroundWindow		-- Родительско окно всех элементов
local closeWindowButton		-- Кнопка "закрытия" окна (выключает его видимость)
local richTextBackground	-- Декоративный фон RichText'а
local richTextInsideWindow		-- RichText в котором отображаются все отчёты
local textEntryBackground	-- Декоративный фон DTextEntry
local textEntryArea		-- DTextEntry через который отправляются запросы на сервер

hook.Add("HUDPaint", "FirstGenerate_CC", function ()	-- Генерация элементов когда vgui загружен
	if not LocalPlayer():IsSuperAdmin() then hook.Remove("HUDPaint", "FirstGenerate_CC") return false end	-- Отмена генерации если игрок не суперадмин

	surface.CreateFont("richTextDefault_CC", {font="CreditsText", size=13, weight = 600})

    mainBackgroundWindow = vgui.Create("DFrame")
	mainBackgroundWindow:SetTitle("Client Console")
	mainBackgroundWindow:SetSize(700,500)
	mainBackgroundWindow:Center()
	mainBackgroundWindow:SetMinWidth(200)
	mainBackgroundWindow:SetMinHeight(200)
	mainBackgroundWindow:SetSizable(true)
	mainBackgroundWindow:ShowCloseButton(false)
	mainBackgroundWindow:SetDeleteOnClose(false)
	mainBackgroundWindow:MakePopup()
	mainBackgroundWindow.Paint = function(self,width,height)
		draw.RoundedBox(0,0,0,width,height,Color(20,20,20,255))
	end
	mainBackgroundWindow.OnSizeChanged = function()
		closeWindowButton:SetPos(mainBackgroundWindow:GetSize()-25,0)
		textEntryBackground:SetPos(mainBackgroundWindow:GetWide()-mainBackgroundWindow:GetWide()+5, mainBackgroundWindow:GetTall()-25)
	    textEntryBackground:SetSize(mainBackgroundWindow:GetWide()-textEntryArea:GetX()-5,20)
        textEntryArea:SetPos(mainBackgroundWindow:GetWide()-mainBackgroundWindow:GetWide()+5, mainBackgroundWindow:GetTall()-25)
	    textEntryArea:SetSize(mainBackgroundWindow:GetWide()-textEntryArea:GetX()-5,20)
	    richTextInsideWindow:SetSize(mainBackgroundWindow:GetWide()-richTextInsideWindow:GetX()-5,mainBackgroundWindow:GetTall()-richTextInsideWindow:GetY()-30)
		richTextBackground:SetSize(mainBackgroundWindow:GetWide()-richTextBackground:GetX()-5,mainBackgroundWindow:GetTall()-richTextBackground:GetY()-30)
	end

    closeWindowButton = vgui.Create("DButton", mainBackgroundWindow)
	closeWindowButton:SetText("X")
	closeWindowButton:SetFont("ChatFont")
	closeWindowButton:SetSize(25,25)
	closeWindowButton:SetPos(mainBackgroundWindow:GetSize()-closeWindowButton:GetWide(),0)
	closeWindowButton:SetTextColor(Color(255,255,255))
	closeWindowButton.Paint = function(self,width,height)
		draw.RoundedBox(0,0,0,width,height,Color(200,0,50,255))
	end
	closeWindowButton.DoClick = function()
        mainBackgroundWindow:SetVisible(false)
	end

	richTextBackground = vgui.Create("DPanel", mainBackgroundWindow)
	richTextBackground:SetPos(mainBackgroundWindow:GetWide()-mainBackgroundWindow:GetWide()+5, mainBackgroundWindow:GetTall()-mainBackgroundWindow:GetTall()+30)
	richTextBackground:SetSize(mainBackgroundWindow:GetWide()-richTextBackground:GetX()-5,mainBackgroundWindow:GetTall()-richTextBackground:GetY()-30)
	richTextBackground:SetBackgroundColor(Color(40,40,40,255))

    richTextInsideWindow = vgui.Create("RichText", mainBackgroundWindow)
    richTextInsideWindow:SetVerticalScrollbarEnabled(true)
    richTextInsideWindow:SetPos(mainBackgroundWindow:GetWide()-mainBackgroundWindow:GetWide()+5, mainBackgroundWindow:GetTall()-mainBackgroundWindow:GetTall()+30)
	richTextInsideWindow:SetSize(mainBackgroundWindow:GetWide()-richTextInsideWindow:GetX()-5,mainBackgroundWindow:GetTall()-richTextInsideWindow:GetY()-30)
	function richTextInsideWindow:PerformLayout() self:SetFontInternal("richTextDefault_CC") end

	textEntryBackground = vgui.Create("DPanel", mainBackgroundWindow)
	textEntryBackground:SetPos(mainBackgroundWindow:GetWide()-mainBackgroundWindow:GetWide()+5, mainBackgroundWindow:GetTall()-25)
	textEntryBackground:SetSize(mainBackgroundWindow:GetWide()-textEntryBackground:GetX()-5,20)
	textEntryBackground:SetBackgroundColor(Color(255,255,255,255))

    textEntryArea = vgui.Create("DTextEntry", mainBackgroundWindow)
	textEntryArea:SetPos(mainBackgroundWindow:GetWide()-mainBackgroundWindow:GetWide()+5, mainBackgroundWindow:GetTall()-25)
	textEntryArea:SetSize(mainBackgroundWindow:GetWide()-textEntryArea:GetX()-5,20)
	textEntryArea:SetPlaceholderText("")
	textEntryArea:SetHistoryEnabled(true)
	textEntryArea:SetPaintBackground(false)
	textEntryArea:SetCursorColor(Color(0,0,0))
	textEntryArea:SetTextColor(Color(0,0,0))
	function textEntryArea:OnEnter(text)	-- Когда игрок кажал Enter
		if string.Trim(self:GetText()) != "" then	-- Проверка на "холостое" нажатие
			if string.Trim(self:GetText()) == "clear" then	-- Кастомная команда очистки клиентской консоли
				richTextInsideWindow:SetText("")
				textEntryArea:SetText("")
				textEntryArea:RequestFocus()
				textEntryArea:AddHistory("clear")
				return
			end
            local cmd = ""
            for word in string.gmatch(text, "%S+") do
				if cmd == "" then
					cmd = word
				else
                	cmd = cmd .. " " .. word
				end
            end
			textEntryArea:AddHistory(cmd)	-- Добавление введённого текста в историю
			net.Start("QueryCMDToServer_CC")	-- Отправление запроса выполнения команды на сервер
			net.WriteString(cmd)
			net.SendToServer()
		else
			richTextInsideWindow:InsertColorChange(100,100,100,255)
			richTextInsideWindow:AppendText("]\n")
			textEntryArea:RequestFocus()
		end
        textEntryArea:SetText("")
        textEntryArea:RequestFocus()
	end
	function textEntryArea:OnKeyCodePressed(key)	-- История введённого текста
		if key == KEY_UP then	-- Стрелка вверх
			textEntryArea.HistoryPos = textEntryArea.HistoryPos + 1
			textEntryArea:UpdateFromHistory()
		elseif key == KEY_DOWN then	-- Стрелка вниз
			textEntryArea.HistoryPos = textEntryArea.HistoryPos - 1
			textEntryArea:UpdateFromHistory()
		end
	end

	mainBackgroundWindow:SetVisible(false)
	concommand.Add("clcs", function () mainBackgroundWindow:SetVisible(true) textEntryArea:RequestFocus() end, function() end, "Opens the Client Console")	-- Консольная команда открывающая окно клиентской консоли
    hook.Remove("HUDPaint", "FirstGenerate_CC")	-- Удаление хука, после генерации элементов он больше не нужен
end)

net.Receive("SendCMDToClient_CC", function ()	-- Приём отчёта с сервера о запросах других суперадминов (ваших тоже)
	local sender = net.ReadString()	-- Кто отправил запрос
	local cmd = net.ReadString()	-- Команда отправленная на выполнение

	richTextInsideWindow:InsertColorChange(100,100,100,255)
	richTextInsideWindow:AppendText("] ")
	richTextInsideWindow:InsertColorChange(255,255,255,255)
	richTextInsideWindow:AppendText(sender .. ": ")
	richTextInsideWindow:InsertColorChange(0,255,255,255)
	if string.find(cmd, "\n") then	-- Проверка наличия второй строки (добавляется на сервере если команда была заблокирована)
		richTextInsideWindow:AppendText(string.sub(cmd, 1, string.find(cmd, "\n")))	-- Вставка команды
		richTextInsideWindow:InsertColorChange(255,0,50,255)
		richTextInsideWindow:AppendText(string.sub(cmd, string.find(cmd, "\n")+1) .. "\n")	-- Вставка ошибки
	else
		richTextInsideWindow:AppendText(cmd .. "\n")	-- Просто вставка команды, если второй строки нет
	end
end)

net.Receive("SendLuaErrorToClient_CC", function ()	-- Приём сообщений о Lua ошибках
	local err = net.ReadString()

	richTextInsideWindow:InsertColorChange(255,0,50,255)
	richTextInsideWindow:AppendText("LUA_ERROR: " .. err .. "\n")
end)