
collectgarbage()

local appFileName = "dashboard"
local appVersion = "1.1"

local isEmulator = false

local deviceType

----------------------------------------------------------------------
-- variables
local lang
local model, owner = " ", " "
local dateNow
local actualConfigFormId = 1

-- central box variables
local cbVoltageSensor1, cbCurrentSensor1, cbCapacitySensor1 = {}, {}, {}
local cbVoltageSensor2, cbCurrentSensor2, cbCapacitySensor2 = {}, {}, {}
local cbTempSensor = {}
local cbVoltage, cbCurrent, cbCapacity, cbCapacityPerCent, cbTemp = {0, 0}, {0, 0}, {0, 0}, {-1, -1}, 0
local cbBatCellCount, cbBatCap = 0, 0
local lastVolt1, lastVolt2 = 0, 0
local volt1Reset, volt2Reset = 0, 0
local cbBatType

-- TX telemetry values
local txTelemetry

-- sparkswitch variables
local ignitionSwitch
local spswVoltageSensor, spswCurrentSensor, spswCapacitySensor, spswRpmSensor, spswTempSensor = {}, {}, {}, {}, {}
local spswVoltage, spswCurrent, spswCapacity, spswRpm, spswTemp, spswCapacityPerCent = 0, 0, 0, -1, -128, -1
local spswBatCellCount, spswBatCap = 0, 0
local spswBatType

-- PBS-T250 variables
local pbsEn
local pbsEnForm
local pbsTempValue = {-128, -128, -128, -128, -128}
local pbsTempMaxValue = {-128, -128, -128, -128, -128}
local pbsSensor = {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}}

-- air pressure
local airPressureEn
local airPressureEnForm
local airPressure = 0
local airPressureSensor = {}
local airPressureNominalValue
local airPressureWarnThreshold, airPressureWarnThresholdPerCent = 0, 0
local airPressureCriticalThreshold, airPressureCriticalThresholdPercent = 0, 0

-- timer variables
local timerSec, timerMin, timerHour = 0, 10, 0
local timerSecInitialValue = 0
local timerMinInitialValue = 10
local timerStartSwitch
local timerResetSwitch
local time, lastTime, newTime = 0, 0, 0

----------------------------------------------------------------------
-- Battery type list
local batTypeList = {"LiFe", "LiPo", "LiIo", "Nixx"}

----------------------------------------------------------------------

local batPercentList = {}
-- life
batPercentList[1] = {
	{2.80,0},
	{3.06,5},
	{3.14,10},
	{3.17,15},
	{3.19,20},
	{3.20,25},
	{3.21,30},
	{3.22,35},
	{3.23,40},
	{3.24,45},
	{3.25,50},
	{3.25,55},
	{3.26,60},
	{3.26,65},
	{3.27,70},
	{3.28,75},
	{3.28,80},
	{3.29,85},
	{3.29,90},
	{3.29,95},
	{3.30,100}}
	
-- lipo
batPercentList[2] = {
	{3.000, 0},           
	{3.250, 5},
	{3.500, 10},
	{3.675, 15},
	{3.696, 20},
	{3.718, 25},
	{3.737, 30},
	{3.753, 35},
	{3.772, 40},
	{3.789, 45},
	{3.807, 50},
	{3.827, 55},
	{3.850, 60},
	{3.881, 65},
	{3.916, 70},
	{3.948, 75},
	{3.987, 80},
	{4.042, 85},
	{4.085, 90},
	{4.115, 95},
	{4.150, 100}}

-- liion
batPercentList[3] = {
	{3.250, 0},
	{3.300, 5},
	{3.327, 10},
	{3.355, 15},
	{3.377, 20},
	{3.395, 25},
	{3.435, 30},
	{3.490, 40},
	{3.630, 60},
	{3.755, 75},
	{3.790, 80},
	{3.840, 85},
	{3.870, 90},
	{3.915, 95},
	{4.050, 100}}

-- nixx
batPercentList[4] = {
	{0.900, 0},           
	{0.970, 5},
	{1.040, 10},
	{1.090, 15},
	{1.120, 20},
	{1.140, 25},
	{1.155, 30},
	{1.175, 40},
	{1.205, 60},
	{1.220, 75},
	{1.230, 80},
	{1.250, 85},
	{1.280, 90},
	{1.330, 95},
	{1.420, 100}}

----------------------------------------------------------------------
-- Read translations
local function setLanguage()
    local lng=system.getLocale()
    local file=io.readall("Apps/Lang/"..appFileName..".jsn")
    local obj=json.decode(file)
    if(obj) then
        lang=obj[lng] or obj[obj.default]
    end
end

----------------------------------------------------------------------
-- Draw fuel bar 
local function fuelBar(ox, oy)
    lcd.drawRectangle (ox, 53 + oy, 20, 11)
    lcd.drawRectangle (ox, 41 + oy, 20, 11)  
    lcd.drawRectangle (ox, 29 + oy, 20, 11)  
    lcd.drawRectangle (ox, 17 + oy, 20, 11)  
    lcd.drawRectangle (ox, 5 + oy, 20, 11)
end

-- Draw bar chart
local function barChart(ox, oy, cellPerc)
    if(cellPerc >= 0) then
        if cellPerc > 50 then
            lcd.setColor(0, 200, 0)  -- green 
        elseif cellPerc > 20 then
            lcd.setColor(255, 128, 0)  -- orange
        else
            lcd.setColor(200, 0, 0)  -- red
        end
        local nSolidBar = math.floor(cellPerc / 20)
        local nFracBar = (cellPerc - nSolidBar * 20) / 20
        local i
        -- Solid bars
        for i = 0, nSolidBar - 1, 1 do 
            lcd.drawFilledRectangle(1 + ox, 54 - i * 12 + oy, 18, 9) 
        end  
        -- Fractional bar
        local y = math.ceil(54 - nSolidBar * 12 + (1 - nFracBar) * 9)
        lcd.drawFilledRectangle(1 + ox, y + oy, 18, 9 * nFracBar)
    end
end

local function horBarChart(x, y, percentage, warning, critical)
    -- bar outlines
    lcd.drawRectangle(71+x,4+y,16,15)
    lcd.drawRectangle(54+x,4+y,16,15)  
    lcd.drawRectangle(37+x,4+y,16,15)  
    lcd.drawRectangle(20+x,4+y,16,15)  
    lcd.drawRectangle(3+x,4+y,16,15)
    
	print("horBarChart, percentage: "..percentage)
	print("horBarChart, warning: "..warning)
	print("horBarChart, critical: "..critical)
	-- fill
	if (percentage > 100) then
		percentage = 100
	end
    if (percentage >= 0) then
        if (percentage <= critical) then
            lcd.setColor(220,0,0) -- Red
        elseif (percentage <= warning) then
			lcd.setColor(255, 128, 0)  -- orange
		else
            lcd.setColor(0,220,0) -- Green
        end
        local nSolidBar = math.floor(percentage / 20)
        local nFracBar = (percentage - nSolidBar * 20) / 20
        local i
        -- Solid bars
        for i = 0, nSolidBar - 1, 1 do 
            lcd.drawFilledRectangle(4+i*17+x,5+y,14,13) 
        end  
        -- Fractional bar
        local xf = math.floor(4 + nSolidBar * 17)
        lcd.drawFilledRectangle(x + xf, 5 + y, 15 * nFracBar, 13)
		
		lcd.setColor(0, 0, 0)
    end
end

local function getRssiScaled(rssi_dBm)
	local val = 0
	
	if (rssi_dBm > 34) then return 9 end
	if (rssi_dBm > 27) then return 8 end
	if (rssi_dBm > 22) then return 7 end
	if (rssi_dBm > 18) then return 6 end
	if (rssi_dBm > 14) then return 5 end
	if (rssi_dBm > 10) then return 4 end
	if (rssi_dBm > 6) then return 3 end
	if (rssi_dBm > 3) then return 2 end
	if (rssi_dBm > 0) then return 1 end
	
	return 0
end

local function rxBox(x, y)
	
	-- draw box
	lcd.drawRectangle(x, y, 317, 71, 7)
	lcd.drawRectangle(x + 1, y + 1, 315, 69, 6)
	
	-- draw title box
	lcd.drawText(5, 2, "Rx/Box", FONT_BOLD)
	
	local txtXOffset = 7
	local txtYOffset = 20
	local txtYOffsetInc = 12
	
	if (isEmulator) then
		txTelemetry.rx1Voltage = 5.5
		txTelemetry.rx1Percent = 98
		txTelemetry.RSSI[1] = 30
		txTelemetry.RSSI[2] = 12
		cbCapacityPerCent[1] = 10
		cbCapacity[1] = 3100
		cbVoltage[1] = 6.25
		cbCapacityPerCent[2] = 45
		cbCapacity[2] = 2200
		cbVoltage[2] = 6.1
	end
	
	-- draw Rx telemetry values
	if (txTelemetry ~= nil) then
		lcd.drawText(txtXOffset, txtYOffset, string.format("Rx1: %.1fV, Q=%d%%, A1/2=%d/%d", txTelemetry.rx1Voltage, txTelemetry.rx1Percent, getRssiScaled(txTelemetry.RSSI[1]), getRssiScaled(txTelemetry.RSSI[2])), FONT_MINI)
		txtYOffset = txtYOffset + txtYOffsetInc
		lcd.drawText(txtXOffset, txtYOffset, string.format("Rx2: %.1fV, Q=%d%%, A1/2=%d/%d", txTelemetry.rx2Voltage, txTelemetry.rx2Percent, getRssiScaled(txTelemetry.RSSI[3]), getRssiScaled(txTelemetry.RSSI[4])), FONT_MINI)
		txtYOffset = txtYOffset + txtYOffsetInc
		lcd.drawText(txtXOffset, txtYOffset, string.format("RxB: %.1fV, Q=%d%%, A1/2=%d/%d", txTelemetry.rxBVoltage, txTelemetry.rxBPercent, getRssiScaled(txTelemetry.RSSI[5]), getRssiScaled(txTelemetry.RSSI[6])), FONT_MINI)
	end
	
	-- draw temperature value
	txtYOffset = txtYOffset + txtYOffsetInc
	lcd.drawText(txtXOffset, txtYOffset, string.format("Temp: %d°C", cbTemp), FONT_MINI)
	
    -- draw battery 1
	txtXOffset = 210
	
	--lcd.drawText(txtXOffset - lcd.getTextWidth(FONT_BOLD,string.format("Bat #1: %.0f%%",cbCapacityPerCent[1])),2,string.format("Bat #1: %.0f%%",cbCapacityPerCent[1]),FONT_BOLD)
	lcd.drawText(txtXOffset - lcd.getTextWidth(FONT_NORMAL, "Bat #1"), 2, "Bat #1")
	lcd.drawText(txtXOffset - lcd.getTextWidth(FONT_MINI, string.format("%.0fmAh", cbCapacity[1])), 23,string.format("%.0fmAh", cbCapacity[1]), FONT_MINI)
	lcd.drawText(txtXOffset - lcd.getTextWidth(FONT_MINI, string.format("%.2fA", cbCurrent[1])), 38, string.format("%.2fA", cbCurrent[1]), FONT_MINI)
	lcd.drawText(txtXOffset - lcd.getTextWidth(FONT_MINI, string.format("%.2fV", cbVoltage[1])), 53, string.format("%.2fV", cbVoltage[1]), FONT_MINI)
    fuelBar(txtXOffset + 5, 0)
	barChart(txtXOffset + 5, 0, cbCapacityPerCent[1])
	lcd.setColor(0, 0, 0)
    
    -- draw battery 2
	txtXOffset = 265
	
    --if (cbCapacityPerCent[2] == -1) then
    --    lcd.drawText(txtXOffset, 2, "Bat #2")
	--else
        --lcd.drawText(txtXOffset, 2, string.format("Bat #2: %.0f%%",cbCapacityPerCent[2]), FONT_BOLD)
		lcd.drawText(txtXOffset, 2, "Bat #2")
        lcd.drawText(txtXOffset, 23, string.format("%.0fmAh", cbCapacity[2]), FONT_MINI)
        lcd.drawText(txtXOffset, 38, string.format("%.2fA", cbCurrent[2]), FONT_MINI)
		lcd.drawText(txtXOffset, 53, string.format("%.2fV", cbVoltage[2]), FONT_MINI)
    --end
    fuelBar(txtXOffset - 25, 0)
    barChart(txtXOffset - 25, 0, cbCapacityPerCent[2])
	lcd.setColor(0, 0, 0)
	
	collectgarbage()
end

local function engineBox(x, y)
	
	if (isEmulator) then
		spswVoltage = 7.2
		spswCurrent = 0.12
		spswCapacity = 1300
		spswCapacityPerCent = 90
		spswTemp = 22
		spswRpm = 1800
	end
	
	-- draw box
	lcd.drawRectangle(x, y, 317, 67, 7)
	lcd.drawRectangle(x + 1, y + 1, 315, 65, 6)
	
	-- draw title box
	lcd.drawText(5, 73, "Engine", FONT_BOLD)
	
	local txtXOffset = 7
	local txtYOffset = 95
	local txtYOffsetInc = 18
	
	-- draw engine telemetry values
	if (spswRpm > -1) then
		lcd.drawText(txtXOffset, txtYOffset, string.format("RPM: %d", spswRpm))
	end
	
	if (spswTemp > -128) then
		txtYOffset = txtYOffset + txtYOffsetInc
		lcd.drawText(txtXOffset, txtYOffset, string.format("Temp: %d°C", spswTemp))
	end
	
	-- draw battery indicator
	txtXOffset = 265
	txtYOffset = 74
	
	--if (spswCapacityPerCent ~= -1) then
		lcd.drawText(txtXOffset, txtYOffset, "Bat")
		txtYOffset = txtYOffset + 19
        lcd.drawText(txtXOffset, txtYOffset,string.format("%.0fmAh", spswCapacity), FONT_MINI)
		txtYOffset = txtYOffset + 15
        lcd.drawText(txtXOffset, txtYOffset, string.format("%.2fA", spswCurrent), FONT_MINI)
		txtYOffset = txtYOffset + 15
		lcd.drawText(txtXOffset, txtYOffset, string.format("%.2fV", spswVoltage), FONT_MINI)
    --end
	fuelBar(txtXOffset - 25, 72)
	barChart(txtXOffset - 25, 72, spswCapacityPerCent)
	lcd.setColor(0, 0, 0)
	
	-- draw timer
	txtXOffset = 317 / 2 - lcd.getTextWidth(FONT_MAXI, "00:00") / 2
	txtYOffset = y + 65 / 2 - lcd.getTextHeight(FONT_MAXI) / 2
	lcd.drawText(txtXOffset, txtYOffset, string.format("%02d:%02d", timerMin, timerSec), FONT_MAXI)
	
	-- ignition status
	txtYOffset = txtYOffset + lcd.getTextHeight(FONT_MAXI) - lcd.getTextHeight(FONT_NORMAL) / 2
	local ignitionSwStatus = system.getInputsVal(ignitionSwitch)
	if (ignitionSwStatus == -1) then
		lcd.setColor(200, 0, 0)
		txtXOffset = 317 / 2 - lcd.getTextWidth(FONT_NORMAL, "Ignition OFF") / 2
		lcd.drawText(txtXOffset, txtYOffset, "Ignition OFF")
	else
		lcd.setColor(0, 200, 0)
		txtXOffset = 317 / 2 - lcd.getTextWidth(FONT_NORMAL, "Ignition ON") / 2
		lcd.drawText(txtXOffset, txtYOffset, "Ignition ON")
	end
	lcd.setColor(0, 0, 0)
	
	collectgarbage()
end

local function airPressureBox(x, y, sizeX, sizeY)
	-- draw box
	lcd.drawRectangle(x, y, sizeX, sizeY, 7)
	lcd.drawRectangle(x + 1, y + 1, sizeX - 2, sizeY - 2, 6)
	
	local yCenterBox = 0
	
	-- draw title box
	lcd.drawText(x + 6, y + (sizeY - lcd.getTextHeight(FONT_NORMAL)) / 2, "Air Pressure", FONT_BOLD)
	
	if (isEmulator) then
		airPressure = 300
		airPressureWarnThresholdPerCent = 80
		airPressureCriticalThresholdPerCent = 50
		airPressureNominalValue = 1000
	end
	
	horBarChart(x + 120, y + (sizeY - 22) / 2, (airPressure / airPressureNominalValue) * 100, airPressureWarnThresholdPerCent, airPressureCriticalThresholdPerCent)
	
	-- draw pressure value
	if (airPressure ~= -128) then
		lcd.drawText(x + 220, y + (sizeY - lcd.getTextHeight(FONT_NORMAL)) / 2, string.format("%d kPa", airPressure), FONT_NORMAL)
	end
	
	collectgarbage()
end

local function pbsTempBox(x, y, sizeX, sizeY)
	-- draw box
	lcd.drawRectangle(x, y, sizeX, sizeY, 7)
	lcd.drawRectangle(x + 1, y + 1, sizeX - 2, sizeY - 2, 6)
	
	-- draw title box
	lcd.drawText(x + 6, y, "PBS-T250", FONT_BOLD)
	
	if (isEmulator) then
		pbsTempValue = {80, 90, 100, 92, 110}
		pbsTempMaxValue = {150, 140, 120, 160, 115}
	end
	
	local txtXOffset = x + 15
	local txtYOffset = y + lcd.getTextHeight(FONT_NORMAL) + 2
	
	for i = 1, 5, 1 do
		if (pbsTempValue[i] ~= -128) then
			lcd.drawText(txtXOffset, txtYOffset, string.format("%d°C", pbsTempMaxValue[i]), FONT_MINI)
			lcd.drawText(txtXOffset, txtYOffset + lcd.getTextHeight(FONT_MINI), string.format("%d°C", pbsTempValue[i]))
			txtXOffset = txtXOffset + lcd.getTextWidth(FONT_NORMAL, "XXXXX°C")
		end
	end
	
	collectgarbage()
end

----------------------------------------------------------------------
-- Draw the telemetry windows
local function telemetryForm1(width,height)
	--print("w = ", width, "h = ", height)
	rxBox(1, 1)
	engineBox(1, 73)
end

local function telemetryForm2(width, height)
	local x, y = 1, 1
	if (pbsEn) then
		pbsTempBox(x, y, 317, 60)
		y = y + 61
	end
	if (airPressureEn) then
		airPressureBox(x, y, 317, 36)
		y = y + 37
	end
end

----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function configForm1()

	form.setTitle("Box Settings")
    
    local sensorsAvailable = {}
    local sensors = system.getSensors()
    local sensList = {}
    local descr = ""
    -- Add sensors
    for index, sensor in ipairs(sensors) do 
        if(sensor.param == 0) then
            descr = sensor.label
            else
            sensList[#sensList+1] = string.format("%s-%s",descr,sensor.label)
            sensorsAvailable[#sensorsAvailable+1] = sensor
        end
    end
    
    -- General setting
    form.addRow(1)
    form.addLabel({label=lang.labelGeneralSettings,font=FONT_BOLD})
	
	form.addRow(2)
    form.addLabel({label=lang.batteryTyp, width = 220})
    form.addSelectbox(batTypeList, cbBatType, true, function(value)
		cbBatType = value
		print("box battery type: "..batTypeList[cbBatType])
		system.pSave("cbBatType", cbBatType)
		end)
    
    form.addRow(2)
    form.addLabel({label=lang.cellCount,width=220})
    form.addIntbox(cbBatCellCount, 0, 24, 2, 0, 1, function(value)
		cbBatCellCount = value
		print(string.format("box battery cell count: %d", cbBatCellCount))
		system.pSave("cbBatCellCount", cbBatCellCount)
		end)
    
    form.addRow(2)
    form.addLabel({label=lang.batteryCapacity})
    form.addIntbox(cbBatCap, 0, 9999, 0, 0, 10, function(value)
		cbBatCap = value
		print(string.format("box battery capacity: %d", cbBatCap))
		system.pSave("cbBatCap", cbBatCap)
		end)
		
	form.addRow(2)
    form.addLabel({label=lang.sensorSettingsTempId})
    form.addSelectbox(sensList,cbTempSensor[3],true,function(value)
		cbTempSensor[1] = sensorsAvailable[value].id
		cbTempSensor[2] = sensorsAvailable[value].param
		cbTempSensor[3] = value
		system.pSave("cbTempSensor", cbTempSensor)
		end)
    
    -- Sensor settings battery 1
    form.addRow(1)
    form.addLabel({label=lang.sensorSettingsBatt1,font=FONT_BOLD})
    
    form.addRow(2)
    form.addLabel({label=lang.sensor_V})
    form.addSelectbox(sensList,cbVoltageSensor1[3],true,function(value)
		cbVoltageSensor1[1] = sensorsAvailable[value].id
		cbVoltageSensor1[2] = sensorsAvailable[value].param
		cbVoltageSensor1[3] = value
		system.pSave("cbVoltageSensor1", cbVoltageSensor1)
		end)
    
    form.addRow(2)
    form.addLabel({label=lang.sensor_A})
    form.addSelectbox(sensList,cbCurrentSensor1[3],true,function(value)
		cbCurrentSensor1[1] = sensorsAvailable[value].id
		cbCurrentSensor1[2] = sensorsAvailable[value].param
		cbCurrentSensor1[3] = value
		system.pSave("cbCurrentSensor1", cbCurrentSensor1)
		end)
    
    form.addRow(2)
    form.addLabel({label=lang.sensor_mAh})
    form.addSelectbox(sensList,cbCapacitySensor1[3],true,function(value)
		cbCapacitySensor1[1] = sensorsAvailable[value].id
		cbCapacitySensor1[2] = sensorsAvailable[value].param
		cbCapacitySensor1[3] = value
		system.pSave("cbCapacitySensor1", cbCapacitySensor1)
		end)
    
    -- Sensor settings battery 2
    form.addRow(1)
    form.addLabel({label=lang.sensorSettingsBatt2,font=FONT_BOLD})
    
    form.addRow(2)
    form.addLabel({label=lang.sensor_V})
    form.addSelectbox(sensList,cbVoltageSensor2[3],true,function(value)
		cbVoltageSensor2[1] = sensorsAvailable[value].id
		cbVoltageSensor2[2] = sensorsAvailable[value].param
		cbVoltageSensor2[3] = value
		system.pSave("cbVoltageSensor2", cbVoltageSensor2)
		end)
    
    form.addRow(2)
    form.addLabel({label=lang.sensor_A})
    form.addSelectbox(sensList,cbCurrentSensor2[3],true,function(value)
		cbCurrentSensor2[1] = sensorsAvailable[value].id
		cbCurrentSensor2[2] = sensorsAvailable[value].param
		cbCurrentSensor2[3] = value
		system.pSave("cbCurrentSensor2", cbCurrentSensor2)
		end)
    
    form.addRow(2)
    form.addLabel({label=lang.sensor_mAh})
    form.addSelectbox(sensList,cbCapacitySensor2[3],true,function(value)
		cbCapacitySensor2[1] = sensorsAvailable[value].id
		cbCapacitySensor2[2] = sensorsAvailable[value].param
		cbCapacitySensor2[3] = value
		system.pSave("cbCapacitySensor2", cbCapacitySensor2)
		end)

    form.addRow(1)
    form.addLabel({label="v"..appVersion.." ",font=FONT_MINI,alignRight=true})
	
	collectgarbage()
end

local function configForm2()
	
	form.setTitle("Engine Related Settings")
	
	local sensorsAvailable = {}
    local sensors = system.getSensors()
    local sensList = {}
    local descr = ""
    -- Add sensors
    for index, sensor in ipairs(sensors) do 
        if(sensor.param == 0) then
            descr = sensor.label
        else
            sensList[#sensList+1] = string.format("%s-%s",descr,sensor.label)
            sensorsAvailable[#sensorsAvailable+1] = sensor
        end
    end
	
	-- General setting
    form.addRow(1)
    form.addLabel({label=lang.labelGeneralSettings,font=FONT_BOLD})
	
	form.addRow(2)
    form.addLabel({label=lang.batteryTyp, width = 220})
    form.addSelectbox(batTypeList, spswBatType, true, function(value)
		spswBatType = value
		print("ignition battery type: "..batTypeList[spswBatType])
		system.pSave("spswBatType", spswBatType)
		end)
	
	form.addRow(2)
    form.addLabel({label=lang.cellCount,width=220})
    form.addIntbox(spswBatCellCount, 0, 24, 2, 0, 1, function(value)
		spswBatCellCount = value
		print(string.format("ignition battery cell count: %d", spswBatCellCount))
		system.pSave("spswBatCellCount", spswBatCellCount)
		end)
    
    form.addRow(2)
    form.addLabel({label=lang.batteryCapacity})
    form.addIntbox(spswBatCap, 0, 9999, 0, 0, 10, function(value)
		spswBatCap = value
		print(string.format("ignition battery capacity: %d", spswBatCap))
		system.pSave("spswBatCap", spswBatCap)
		end)
	
	-- ignition switch
	form.addRow(2)
	form.addLabel({label="Ignition switch"})
	form.addInputbox(ignitionSwitch, false, function(value)
		ignitionSwitch = value
		system.pSave("ignitionSwitch", ignitionSwitch)
	end)
	
	-- sparkswitch sensor
	form.addRow(1)
    form.addLabel({label="Sparkswitch Sensor IDs",font=FONT_BOLD})
	
	-- voltage
	form.addRow(2)
    form.addLabel({label="Voltage"})
    form.addSelectbox(sensList, spswVoltageSensor[3], true, function(value)
		spswVoltageSensor[1] = sensorsAvailable[value].id
		spswVoltageSensor[2] = sensorsAvailable[value].param
		spswVoltageSensor[3] = value
		system.pSave("spswVoltageSensor",spswVoltageSensor)
		end)
		
	-- current	
	form.addRow(2)
    form.addLabel({label="Current"})
    form.addSelectbox(sensList, spswCurrentSensor[3], true, function(value)
		spswCurrentSensor[1] = sensorsAvailable[value].id
		spswCurrentSensor[2] = sensorsAvailable[value].param
		spswCurrentSensor[3] = value
		system.pSave("spswCurrentSensor", spswCurrentSensor)
		end)
		
	-- capacity
	form.addRow(2)
    form.addLabel({label="Capacity"})
    form.addSelectbox(sensList, spswCapacitySensor[3], true, function(value)
		spswCapacitySensor[1] = sensorsAvailable[value].id
		spswCapacitySensor[2] = sensorsAvailable[value].param
		spswCapacitySensor[3] = value
		system.pSave("spswCapacitySensor", spswCapacitySensor)
		end)
	
	-- rpm
	form.addRow(2)
    form.addLabel({label="RPM"})
    form.addSelectbox(sensList, spswRpmSensor[3], true, function(value)
		spswRpmSensor[1] = sensorsAvailable[value].id
		spswRpmSensor[2] = sensorsAvailable[value].param
		spswRpmSensor[3] = value
		system.pSave("spswRpmSensor", spswRpmSensor)
		end)
		
	-- temperature
	form.addRow(2)
    form.addLabel({label="Temperature"})
    form.addSelectbox(sensList, spswTempSensor[3], true, function(value)
		spswTempSensor[1] = sensorsAvailable[value].id
		spswTempSensor[2] = sensorsAvailable[value].param
		spswTempSensor[3] = value
		system.pSave("spswTempSensor", spswTempSensor)
		end)
		
	-- pbs sensors
	form.addRow(1)
    form.addLabel({label="PBS Sensor IDs",font=FONT_BOLD})
	
	form.addRow(2)
    form.addLabel({label = "Enabled"})
	pbsEnForm = form.addCheckbox(pbsEn, function(value)
		pbsEn = not pbsEn
		system.pSave("pbsEn", pbsEn and 1 or 0)
		form.setValue(pbsEnForm, pbsEn)
		form.reinit(2)
		end)
	
	if (pbsEn) then
		for i = 1, 5, 1 do
			form.addRow(2)
			form.addLabel({label = "Probe #"..i, width = 220})
			form.addSelectbox(sensList, pbsSensor[i][3], true, function(value)
			pbsSensor[i][1] = sensorsAvailable[value].id
			pbsSensor[i][2] = sensorsAvailable[value].param
			pbsSensor[i][3] = value
			print(string.format("pbsSensor[%d]: %d", i, pbsSensor[i]))
			system.pSave("pbsSensor", pbsSensor)
			end)
		end
	end

	collectgarbage()
end

local function configForm3()

	form.setTitle("Timer Configuration")
	
	form.addRow(3)
	form.addLabel({label="Initial value", width = 140})
	
	form.addIntbox(timerMinInitialValue, 0, 99, 10, 0, 1, function(value)
		timerMinInitialValue = value
		system.pSave("timerMinInitialValue", timerMinInitialValue)
		end, {label = " min"})
		
	form.addIntbox(timerSecInitialValue, 0,59, 10, 0, 1, function(value)
		timerSecInitialValue = value
		system.pSave("timerSecInitialValue", timerSecInitialValue)
		end, {label = " sec"})
		
	form.addRow(2)
	form.addLabel({label="Start switch"})
	form.addInputbox(timerStartSwitch, false, function(value)
		timerStartSwitch = value
		system.pSave("timerStartSwitch", timerStartSwitch)
	end)
	
	form.addRow(2)
	form.addLabel({label="Reset switch"})
	form.addInputbox(timerResetSwitch, false, function(value)
		timerResetSwitch = value
		system.pSave("timerResetSwitch", timerResetSwitch)
	end)
	
	collectgarbage()
end

local function configForm4()

	form.setTitle("Misc Configuration")
	
	local sensorsAvailable = {}
    local sensors = system.getSensors()
    local sensList = {}
    local descr = ""
    -- Add sensors
    for index, sensor in ipairs(sensors) do 
        if(sensor.param == 0) then
            descr = sensor.label
        else
            sensList[#sensList+1] = string.format("%s-%s",descr,sensor.label)
            sensorsAvailable[#sensorsAvailable+1] = sensor
        end
    end
	
	-- General setting
    form.addRow(1)
    form.addLabel({label = "Air Pressure", font = FONT_BOLD})
	
	form.addRow(2)
    form.addLabel({label = "Enabled"})
	airPressureEnForm = form.addCheckbox(airPressureEn, function(value)
		airPressureEn = not airPressureEn
		system.pSave("airPressureEn", airPressureEn and 1 or 0)
		form.setValue(airPressureEnForm, airPressureEn)
		form.reinit(4)
		end)
	
	if (airPressureEn) then
		form.addRow(2)
		form.addLabel({label = "Sensor"})
		form.addSelectbox(sensList, airPressureSensor[3], true, function(value)
			airPressureSensor[1] = sensorsAvailable[value].id
			airPressureSensor[2] = sensorsAvailable[value].param
			airPressureSensor[3] = value
			system.pSave("airPressureSensor", airPressureSensor)
			end)
			
		form.addRow(3)
		form.addLabel({label="Nominal Value (kPa)", width = 220})
		form.addIntbox(airPressureNominalValue, 0, 1024, 10, 0, 1, function(value)
			airPressureNominalValue = value
			airPressureWarnThresholdPerCent = airPressureWarnThreshold / airPressureNominalValue * 100
			airPressureCriticalThresholdPerCent = airPressureCriticalThreshold / airPressureNominalValue * 100
			system.pSave("airPressureNomVal", airPressureNominalValue)
			end)
			
		form.addRow(3)
		form.addLabel({label="Warning Threshold", width = 220})
		form.addIntbox(airPressureWarnThreshold, 0, 2048, 10, 0, 1, function(value)
			airPressureWarnThreshold = value
			airPressureWarnThresholdPerCent = airPressureWarnThreshold / airPressureNominalValue * 100
			system.pSave("airPressureWarnTh", airPressureWarnThreshold)
			end)
			
		form.addRow(3)
		form.addLabel({label="Critical Threshold", width = 220})
		form.addIntbox(airPressureCriticalThreshold, 0, 2048, 10, 0, 1, function(value)
			airPressureCriticalThreshold = value
			airPressureCriticalThresholdPerCent = airPressureCriticalThreshold / airPressureNominalValue * 100
			system.pSave("airPressureCritTh", airPressureCriticalThreshold)
			end)
	end
	
	collectgarbage()
end

local function initForm(id)
	actualConfigFormId = id
	
	if (id == 1) then
		configForm1()
	elseif (id == 2) then
		configForm2()
	elseif (id == 3) then
		configForm3()
	elseif (id == 4) then
		configForm4()
	end
	
	form.setButton(1, "Box", actualConfigFormId == 1 and HIGHLIGHTED or ENABLED)
	form.setButton(2, "Eng", actualConfigFormId == 2 and HIGHLIGHTED or ENABLED)
	form.setButton(3, "Timer", actualConfigFormId == 3 and HIGHLIGHTED or ENABLED)
	form.setButton(4, "Misc", actualConfigFormId == 4 and HIGHLIGHTED or ENABLED)
	
	collectgarbage()
end

local function keyPressed(key)  
	if (key == KEY_1 and actualConfigFormId ~= 1) then      
		form.reinit(1)
	elseif (key == KEY_2 and actualConfigFormId ~= 2) then  
		form.reinit(2)
	elseif (key == KEY_3 and actualConfigFormId ~= 3) then  
		form.reinit(3)
	elseif (key == KEY_4) then
		form.reinit(4)
	--[[elseif (key == KEY_5 and formID == 1) then
		form.preventDefault()
		form.reinit(1)]]
	end
end

----------------------------------------------------------------------
-- Count percentage from cell voltage
local function percCell(batType, cellVoltage)
    local result = 0
    local cellfull, cellempty = batPercentList[batType][#batPercentList][1], batPercentList[batType][1][1]
    
    if(cellVoltage >= cellfull)then                                            
      result = 100
    elseif(cellVoltage <= cellempty)then
      result = 0
    else
        for i, v in ipairs(batPercentList[batType]) do     
            -- Interpolate values                             
            if v[1] >= cellVoltage and i > 1 then
                local lastVal = batPercentList[batType][i - 1]
                result = (cellVoltage - lastVal[1]) / (v[1] - lastVal[1])
                result = result * (v[2] - lastVal[2]) + lastVal[2]
                break
            end
        end
    end
    result = math.modf(result)
    return result
end

----------------------------------------------------------------------
-- timer
local function timer()
	local newTime = system.getTimeCounter()
	local reset = system.getInputsVal(timerResetSwitch)
	local start = system.getInputsVal(timerStartSwitch)

	if (reset == 1) then
		time = timerMinInitialValue * 60 + timerSecInitialValue
	end
	
	if (start == 1) then		
		if newTime > (lastTime + 1000) then
			lastTime = newTime
			if (time > 0) then
				time = time - 1
			else
				time = time + 1
			end
		end
	end
	
	timerHour = math.floor(time / 3600)
	timerMin = math.floor(time / 60) - timerHour * 60
	timerSec = time - timerMin * 60
end

----------------------------------------------------------------------
-- 
local function loop()

	timer()

	txTelemetry = system.getTxTelemetry()
    
    local sensor = {}
	
	-- box battery #1 voltage
    sensor = system.getSensorValueByID(cbVoltageSensor1[1], cbVoltageSensor1[2])
    if (sensor and sensor.valid) then
        cbVoltage[1] = sensor.value
        if (cbVoltage[1] >= lastVolt1 * 1.02)then
            volt1Reset = 1
        end
    end
    
	-- box battery #1 current
    sensor = system.getSensorValueByID(cbCurrentSensor1[1], cbCurrentSensor1[2])
    if (sensor and sensor.valid) then
        cbCurrent[1] = sensor.value 
    end
    
	-- box battery #1 capacity
    sensor = system.getSensorValueByID(cbCapacitySensor1[1], cbCapacitySensor1[2])
    if(sensor and sensor.valid) then
        cbCapacity[1] = sensor.value 
        cbCapacityPerCent[1] = (1 - (cbCapacity[1] / cbBatCap)) * 100
        local tmpCellPerc = percCell(cbBatType, cbVoltage[1] / cbBatCellCount)
        if (cbCapacityPerCent[1] - tmpCellPerc > 15)then
            cbCapacityPerCent[1] = tmpCellPerc
        end
    end
    
	-- box battery #2 voltage
    local sensor = system.getSensorValueByID(cbVoltageSensor2[1], cbVoltageSensor2[2])
    if(sensor and sensor.valid) then
        cbVoltage[2] = sensor.value
        if(cbVoltage[2] >= lastVolt2 * 1.02)then
            volt2Reset = 1
        end
    end
    
	-- box battery #2 current
    sensor = system.getSensorValueByID(cbCurrentSensor2[1], cbCurrentSensor2[2])
    if(sensor and sensor.valid) then
        cbCurrent[2] = sensor.value 
    end
    
	-- box battery #2 capacity
    sensor = system.getSensorValueByID(cbCapacitySensor2[1], cbCapacitySensor2[2])
    if(sensor and sensor.valid) then
        cbCapacity[2] = sensor.value 
        cbCapacityPerCent[2] = (1 - (cbCapacity[2] / cbBatCap)) * 100
        local tmpCellPerc=percCell(cbBatType, cbVoltage[2] / cbBatCellCount)
        if (cbCapacityPerCent[2] - tmpCellPerc > 15)then
            cbCapacityPerCent[2] = tmpCellPerc
        end
    end
	
	-- box temperature
	sensor = system.getSensorValueByID(cbTempSensor[1], cbTempSensor[2])
    if(sensor and sensor.valid) then
        cbTemp = sensor.value 
    end
	
	-- sparkswitch voltage
    sensor = system.getSensorValueByID(spswVoltageSensor[1], spswVoltageSensor[2])
    if (sensor and sensor.valid) then
        spswVoltage = sensor.value
    end
	
	-- sparkswitch current
	sensor = system.getSensorValueByID(spswCurrentSensor[1], spswCurrentSensor[2])
    if (sensor and sensor.valid) then
        spswCurrent = sensor.value
    end
	
	-- sparkswitch capacity
	sensor = system.getSensorValueByID(spswCapacitySensor[1], spswCapacitySensor[2])
    if(sensor and sensor.valid) then
        spswCapacity = sensor.value 
        spswCapacityPerCent = (1 - (spswCapacity / spswBatCap)) * 100
        local tmpCellPerc = percCell(spswBatType, spswVoltage / spswBatCellCount)
        if(spswCapacityPerCent - tmpCellPerc > 15)then
            spswCapacityPerCent = tmpCellPerc
        end
    end
	
	-- sparkswitch temperature
	sensor = system.getSensorValueByID(spswTempSensor[1], spswTempSensor[2])
    if(sensor and sensor.valid) then
        spswTemp = sensor.value
	else
		spswTemp = -128
    end
	
	-- sparkswitch rpm
	sensor = system.getSensorValueByID(spswRpmSensor[1], spswRpmSensor[2])
    if(sensor and sensor.valid) then
        spswRpm = sensor.value
	else
		spswRpm = -1
    end
	
	-- air pressure
	if (airPressureEn) then
		sensor = system.getSensorValueByID(airPressureSensor[1], airPressureSensor[2])
		if(sensor and sensor.valid) then
			airPressure = sensor.value 
		else
			airPressure = -128
		end
	end
	
	-- pbs temperature
	if (pbsEn) then
		for i = 1, 5, 1 do
			sensor = system.getSensorValueByID(pbsSensor[i][1], pbsSensor[i][2])
			if(sensor and sensor.valid) then
				pbsTempValue[i] = sensor.value
				if (pbsTempValue[i] > pbsTempMaxValue[i]) then
					pbsTempMaxValue[i] = pbsTempValue[i]
				end
			else
				pbsTempValue[i] = -128
			end
		end
	end
    
    if(volt1Reset == 1 and volt2Reset == 1)then
        -- reset CB
        print("Reset")
        system.setControl(1, 1, 0)
        volt1Reset = 0
        volt2Reset = 0
        system.pSave("lastVolt1", cbVoltage[1] * 10)
        system.pSave("lastVolt2", cbVoltage[2] * 10)
    else
        system.setControl(1, -1, 0)
    end
    
    system.pSave("volt1Reset",volt1Reset)
    system.pSave("volt2Reset",volt2Reset)
    
end

-- Application initialization
local function init(code1)
	
	model = system.getProperty("Model")
	owner = system.getUserName()
	dateNow = system.getDateTime()
    
    -- initialize variables
    cbVoltageSensor1 = system.pLoad("cbVoltageSensor1",{0,0,0})
    cbCurrentSensor1 = system.pLoad("cbCurrentSensor1",{0,0,0})
    cbCapacitySensor1 = system.pLoad("cbCapacitySensor1",{0,0,0})
    cbVoltageSensor2 = system.pLoad("cbVoltageSensor2",{0,0,0})
    cbCurrentSensor2 = system.pLoad("cbCurrentSensor2",{0,0,0})
    cbCapacitySensor2 = system.pLoad("cbCapacitySensor2",{0,0,0})
	cbTempSensor = system.pLoad("cbTempSensor",{0,0,0})
    cbBatCellCount = system.pLoad("cbBatCellCount", 0)
    cbBatType = system.pLoad("cbBatType", 0)
    cbBatCap = system.pLoad("cbBatCap", 0)
	
	timerSecInitialValue = system.pLoad("timerSecInitialValue", 0)
	timerMinInitialValue = system.pLoad("timerMinInitialValue", 10)
	timerStartSwitch = system.pLoad("timerStartSwitch")
	timerResetSwitch = system.pLoad("timerResetSwitch")
	
	ignitionSwitch = system.pLoad("ignitionSwitch")
	spswVoltageSensor = system.pLoad("spswVoltageSensor",{0,0,0})
	spswCurrentSensor = system.pLoad("spswCurrentSensor",{0,0,0})
	spswCapacitySensor = system.pLoad("spswCapacitySensor",{0,0,0})
	spswRpmSensor = system.pLoad("spswRpmSensor",{0,0,0})
	spswTempSensor = system.pLoad("spswTempSensor",{0,0,0})
	spswBatCellCount = system.pLoad("spswBatCellCount", 0)
    spswBatType = system.pLoad("spswBatType", 0)
    spswBatCap = system.pLoad("spswBatCap", 0)
	
	pbsEn = system.pLoad("pbsEn", 0) == 1 and true or false
	pbsSensor = system.pLoad("pbsSensor", {{0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}})
	
	airPressureEn = system.pLoad("airPressureEn", 0) == 1 and true or false
	airPressureSensor = system.pLoad("airPressureSensor", {0, 0, 0})
	airPressureWarnThreshold = system.pLoad("airPressureWarnTh", 0)
	airPressureCriticalThreshold = system.pLoad("airPressureCritTh", 0)
	airPressureNominalValue = system.pLoad("airPressureNomVal", 1)
	airPressureWarnThresholdPerCent = airPressureWarnThreshold / airPressureNominalValue * 100
	airPressureCriticalThresholdPerCent = airPressureCriticalThreshold / airPressureNominalValue * 100
    
    -- register form
    system.registerForm(1, MENU_MAIN, lang.appName, initForm, keyPressed)
    system.registerTelemetry(1, model.." "..lang.appName.." 1", 4, telemetryForm1)
	system.registerTelemetry(2, model.." "..lang.appName.." 2", 4, telemetryForm2)
    
    -- init CB reset
    system.registerControl(1,"DashboardReset", "dbReset")
    system.setControl(1,-1,0)
    lastVolt1 = system.pLoad("lastVolt1",0)/10
    lastVolt2 = system.pLoad("lastVolt2",0)/10
    volt1Reset = system.pLoad("volt1Reset",0)
    volt2Reset = system.pLoad("volt2Reset",0)
	
	deviceType, isEmulator = system.getDeviceType()
	
	collectgarbage()
end
----------------------------------------------------------------------
setLanguage()
collectgarbage()
return {init = init, loop = loop, author = "P.PERONNARD", version = appVersion, name = lang.appName}
