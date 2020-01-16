
collectgarbage()

local appAuthor = "P. PERONNARD"
local appFileName = "model-data"
local appVersion = "1.0"
local poweredBy = "Powered by "..appAuthor.." v"..appVersion

local DEBUG = false

----------------------------------------------------------------------
-- variables
local lang
local model, owner = " ", " "
local dateNow
local actualConfigFormId = 1

local wingspan
local weigth
local weigthUnit
local weigthUnitList = {"kg", "g"}

local cgLoc

local throwAileronUp, throwAileronDown
local throwAileronUnit
local throwElevatorUp, throwElevatorDown
local throwElevatorUnit
local throwRudder
local throwRudderUnit

local rxBatType
local rxBatCapacity = {0, 0}
local engineBatType
local engineBatCapacity = {0, 0}

local auxBatName = {" ", " ", " "}
local auxBatType = {0, 0, 0}
local auxBatCapacity = {0, 0, 0}

local throwUnitList = {"mm", "°"}
local batTypeList = {"LiFe", "LiPo", "LiIo", "Nixx"}

----------------------------------------------------------------------
-- read language data
local function setLanguage()
    local lng=system.getLocale()
    local file=io.readall("Apps/Lang/"..appFileName..".jsn")
    local obj=json.decode(file)
    if(obj) then
        lang=obj[lng] or obj[obj.default]
    end
end

-- Draw the telemetry windows
local function telemetryForm1(width,height)
	--print("w = ", width, "h = ", height)
end

----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function configForm1()

	form.setTitle("")
    
	form.addRow(2)
    form.addLabel({label=lang.wingspan, width = 220})
    form.addIntbox(wingspan, 0, 16384, 10, 0, 1, function(value)
		wingspan = value
		print(string.format("wingspan: %d", wingspan))
		system.pSave("wingspan", wingspan)
		end, {label = " cm"})
		
	form.addRow(3)
    form.addLabel({label=lang.weigth, width = 130})
    form.addIntbox(weigth, 0, 16384, 10, 0, 10, function(value)
		weigth = value
		print(string.format("weigth: %d", weigth))
		system.pSave("weigth", weigth)
		end)
	form.addSelectbox(weigthUnitList, weigthUnit, true, function(value)
		weigthUnit = value
		print("weigthUnit: "..weigthUnitList[weigthUnit])
		system.pSave("weigthUnit", weigthUnit)
		end)
		
	form.addRow(2)
    form.addLabel({label=lang.cgLoc, width = 220})
    form.addIntbox(cgLoc, 0, 1024, 10, 0, 1, function(value)
		cgLoc = value
		print(string.format("cgLoc: %d", cgLoc))
		system.pSave("cgLoc", cgLoc)
		end, {label = " mm"})
	
	form.addSpacer(318, 8)
    form.addLabel({label = lang.ctrlThrow, font=FONT_BOLD})
	
	form.addRow(3)
    form.addLabel({label = lang.throwAileronUp, width = 130})
    form.addIntbox(throwAileronUp, 0, 16384, 10, 0, 10, function(value)
		throwAileronUp = value
		print(string.format("throwAileronUp: %d", throwAileronUp))
		system.pSave("throwAileronUp", throwAileronUp)
		end)
	form.addSelectbox(throwUnitList, throwAileronUnit, true, function(value)
		throwAileronUnit = value
		print("throwAileronUnit: "..throwUnitList[throwAileronUnit])
		system.pSave("throwAileronUnit", throwAileronUnit)
		end)
	form.addRow(3)
    form.addLabel({label = lang.throwAileronDown, width = 130})
    form.addIntbox(throwAileronDown, 0, 16384, 10, 0, 10, function(value)
		throwAileronDown = value
		print(string.format("throwAileronDown: %d", throwAileronDown))
		system.pSave("throwAileronDown", throwAileronDown)
		end)
		
	form.addSpacer(318, 25)
	form.addRow(3)
    form.addLabel({label = lang.throwElevatorUp, width = 130})
    form.addIntbox(throwElevatorUp, 0, 16384, 10, 0, 10, function(value)
		throwElevatorUp = value
		print(string.format("throwElevatorUp: %d", throwElevatorUp))
		system.pSave("throwElevatorUp", throwElevatorUp)
		end)
	form.addSelectbox(throwUnitList, throwElevatorUnit, true, function(value)
		throwElevatorUnit = value
		print("throwElevatorUnit: "..throwUnitList[throwElevatorUnit])
		system.pSave("throwElevatorUnit", throwElevatorUnit)
		end)
	form.addRow(3)
    form.addLabel({label = lang.throwElevatorDown, width = 130})
    form.addIntbox(throwElevatorDown, 0, 16384, 10, 0, 10, function(value)
		throwElevatorDown = value
		print(string.format("throwElevatorDown: %d", throwElevatorDown))
		system.pSave("throwElevatorDown", throwElevatorDown)
		end)
		
	form.addSpacer(318, 25)
	form.addRow(3)
    form.addLabel({label = lang.rudder, width = 130})
    form.addIntbox(throwRudder, 0, 16384, 10, 0, 10, function(value)
		throwRudder = value
		print(string.format("throwRudder: %d", throwRudder))
		system.pSave("throwRudder", throwRudder)
		end)
	form.addSelectbox(throwUnitList, throwRudderUnit, true, function(value)
		throwRudderUnit = value
		print("throwRudderUnit: "..throwUnitList[throwRudderUnit])
		system.pSave("throwRudderUnit", throwRudderUnit)
		end)
	
    form.addSpacer(318, 8)
    form.addRow(1)
    form.addLabel({label = lang.appName.." "..poweredBy, font = FONT_MINI, alignRight = true})
	
	collectgarbage()
end

local function configForm2()

	form.setTitle("Power")
    
	-- Rx
	form.addRow(1)
	form.addLabel({label = "Rx", font=FONT_BOLD})
	
	form.addRow(2)
    form.addLabel({label = "Type", width = 220})
    form.addSelectbox(batTypeList, rxBatType, true, function(value)
		rxBatType = value
		print("rxBatType: "..batTypeList[rxBatType])
		system.pSave("rxBatType", rxBatType)
		end)
		
	form.addRow(2)
    form.addLabel({label="#1 "..lang.batCapacity, width = 220})
    form.addIntbox(rxBatCapacity[1], 0, 8192, 10, 0, 1, function(value)
		rxBatCapacity[1] = value
		print(string.format("rxBatCapacity[1]: %d", rxBatCapacity[1]))
		system.pSave("rxBatCap", rxBatCapacity)
		end, {label = " mAh"})
		
	form.addRow(2)
    form.addLabel({label="#2 "..lang.batCapacity, width = 220})
    form.addIntbox(rxBatCapacity[2], 0, 8192, 10, 0, 1, function(value)
		rxBatCapacity[2] = value
		print(string.format("rxBatCapacity[2]: %d", rxBatCapacity[2]))
		system.pSave("rxBatCap", rxBatCapacity)
		end, {label = " mAh"})
	
	-- Engine
	form.addSpacer(318, 8)
	form.addLabel({label = lang.engineIgnMotor, font=FONT_BOLD})
	form.addRow(2)
    form.addLabel({label = "Type", width = 220})
    form.addSelectbox(batTypeList, engineBatType, true, function(value)
		engineBatType = value
		print("engineBatType: "..batTypeList[engineBatType])
		system.pSave("engineBatType", engineBatType)
		end)
		
	form.addRow(2)
    form.addLabel({label = lang.batCapacity, width = 220})
    form.addIntbox(engineBatCapacity[1], 0, 8192, 10, 0, 1, function(value)
		engineBatCapacity[1] = value
		print(string.format("engineBatCapacity: %d", engineBatCapacity))
		system.pSave("engineBatCap", engineBatCapacity)
		end, {label = " mAh"})
		
	-- Aux
	form.addSpacer(318, 8)
	form.addLabel({label = "Aux", font=FONT_BOLD})
	for i = 1, 3, 1 do
		form.addRow(2)
		form.addLabel({label = "#"..i.." "..lang.auxBatName, width = 220})
		form.addTextbox(auxBatName[i], 32, function(value)
			auxBatName[i] = value
			print("auxBatName["..i.."]: "..auxBatName[i])
			system.pSave("auxBatName", auxBatName)
			end)
			
		form.addRow(2)
		form.addLabel({label = "#"..i.." Type", width = 220})
		form.addSelectbox(batTypeList, auxBatType[i], true, function(value)
			auxBatType[i] = value
			print("auxBatType["..i.."]: "..batTypeList[auxBatType[i]])
			system.pSave("rxBatType", auxBatType)
			end)
			
		form.addRow(2)
		form.addLabel({label="#"..i.." "..lang.batCapacity, width = 220})
		form.addIntbox(auxBatCapacity[i], 0, 8192, 10, 0, 1, function(value)
		auxBatCapacity[i] = value
		print(string.format("rxBatCapacity[%d]: %d", i, auxBatCapacity[i]))
		system.pSave("auxBatCap", auxBatCapacity)
		end, {label = " mAh"})
		
		form.addSpacer(318, 8)
	end
    
    
    form.addRow(1)
    form.addLabel({label = lang.appName.." "..poweredBy, font = FONT_MINI, alignRight =true})
	
	collectgarbage()
end

local function initForm(id)
	actualConfigFormId = id
	
	if (id == 1) then
		configForm1()
	elseif (id == 2) then
		configForm2()
	end
	
	form.setButton(1, "1", actualConfigFormId == 1 and HIGHLIGHTED or ENABLED)
	form.setButton(2, "2", actualConfigFormId == 2 and HIGHLIGHTED or ENABLED)
	
	collectgarbage()
end

local function keyPressed(key)  
	if (key == KEY_1 and actualConfigFormId ~= 1) then      
		form.reinit(1)
	elseif (key == KEY_2 and actualConfigFormId ~= 2) then  
		form.reinit(2)
	elseif (key == KEY_3 and actualConfigFormId ~= 3) then  
		form.reinit(3)
	--[[elseif (key == KEY_4) then
		form.reinit(1)
	elseif (key == KEY_5 and formID == 1) then
		form.preventDefault()
		form.reinit(1)]]
	end
end

----------------------------------------------------------------------
-- 
local function loop()
    
end

-- Application initialization
local function init(code1)
	
	model = system.getProperty("Model")
	owner = system.getUserName()
	dateNow = system.getDateTime()
    
    -- initialize variables
    wingspan = system.pLoad("wingspan", 0)
	weigth = system.pLoad("weigth", 0)
	weigthUnit = system.pLoad("weigthUnit", 0)
	cgLoc = system.pLoad("cgLoc", 0)
	throwAileronUp = system.pLoad("throwAileronUp", 0)
	throwAileronDown = system.pLoad("throwAileronDown", 0)
	throwAileronUnit = system.pLoad("throwAileronUnit", 0)
	throwElevatorUp = system.pLoad("throwElevatorUp", 0)
	throwElevatorDown = system.pLoad("throwElevatorDown", 0)
	throwElevatorUnit = system.pLoad("throwElevatorUnit", 0)
	throwRudder = system.pLoad("throwRudder", 0)
	throwRudderUnit = system.pLoad("throwRudderUnit", 0)
	
	rxBatType = system.pLoad("rxBatType", 0)
	rxBatCapacity = system.pLoad("rxBatCap", {0, 0})
	engineBatType = system.pLoad("engineBatType", 0)
	engineBatCapacity = system.pLoad("engineBatCap", {0, 0})
	auxBatName = system.pLoad("auxBatName", {" ", " ", " "})
	auxBatType = system.pLoad("auxBatType", {0, 0, 0})
	auxBatCapacity = system.pLoad("auxBatCap", {0, 0, 0})
    
    -- register form
    system.registerForm(1, MENU_MAIN, lang.appName, initForm, keyPressed)
	
	collectgarbage()
end
----------------------------------------------------------------------
setLanguage()
collectgarbage()
return {init = init, loop = loop, author = appAuthor, version = appVersion, name = lang.appName}
