script_name("Admin Tools")
script_author("tsinsandro_")

require "lib.moonloader"
local inicfg = require "inicfg"
local sampev = require "lib.samp.events"

local imgui = require "imgui"
local encoding = require "encoding"
encoding.default = "CP1251"
u8 = encoding.UTF8

-- Try to load FontAwesome
local fa = nil
local fa_font = nil
local fa_glyph_ranges = nil
local fa_loaded = false
if pcall(function() fa = require "fAwesome5" end) then
    fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
    fa_loaded = true
end

local auto_report = imgui.ImBool(false)
local auto_report_enabled = false


-- === CONFIG ===
local warningDisplayTime = 0
local warningDuration = 5 -- seconds to show the warning
local font_warning
local config_file = "admin_tools.ini"
local config = inicfg.load({
    main = {
        password = "",
        auto_az = false,
        quick_reply1 = "Movidivar!",
        quick_reply2 = "Nu a'offtopebt!",
        quick_reply3 = "Gtxovt daelodot.",
        quick_reply4 = "Mogvarebulia",
        quick_reply5 = "Motamashe ar argvevs wesebs",
        quick_reply6 = "Gafrtxilebbulia.",
        quick_reply7 = "Ar verevit RP'shi",
        quick_reply8 = "Gaecanit wesebs forumze",
        quick_reply9 = "Ar gvaqvs informacia."
    }
}, config_file)

-- === VARIABLES ===
local show_menu = imgui.ImBool(false)
local show_reply_gui = imgui.ImBool(false)
local current_tab = imgui.ImInt(0) -- 0 = main, 1 = admin soft
local input_password = imgui.ImBuffer(256)
local auto_az = imgui.ImBool(config.main.auto_az)
local invis_enabled = imgui.ImBool(false)
local reply_buffers = {}
for i = 1, 9 do
    reply_buffers[i] = imgui.ImBuffer(256)
end
if not clickwarp_enabled then clickwarp_enabled = imgui.ImBool(false) end
if not air_enabled then air_enabled = imgui.ImBool(false) end
local vrender_enabled = imgui.ImBool(false)
local vehicle_font = nil
local air_enabled = imgui.ImBool(false)
local air_thread = nil
local air_pow = 0.7
local air_pow_car = 1.9

local lastReportDialogId = nil
local lastReportPlayerId = nil
local lastReportReason = ""

-- === GUI STATE ===
local password_visible = imgui.ImBool(false)
local toggle_auto_apanel = imgui.ImBool(false)
local sidebar_width = 200
local purple_color = imgui.ImVec4(0.55, 0.01, 0.99, 1.0) -- #8c03fc
local purple_dark = imgui.ImVec4(0.35, 0.01, 0.65, 1.0)
local dark_bg = imgui.ImVec4(0.15, 0.15, 0.15, 1.0)
local darker_bg = imgui.ImVec4(0.10, 0.10, 0.10, 1.0)

-- FontAwesome icon function
local function get_fa_icon(icon_name, fallback)
    if fa_loaded and fa and fa[icon_name] then
        return fa[icon_name]
    end
    return fallback or ""
end

-- FontAwesome icon getters (lazy loading)
local function fa_home() return get_fa_icon("ICON_FA_HOME", "H") end
local function fa_save() return get_fa_icon("ICON_FA_SAVE", "S") end
local function fa_bell() return get_fa_icon("ICON_FA_BELL", "B") end
local function fa_question() return get_fa_icon("ICON_FA_QUESTION_CIRCLE", "?") end
local function fa_volume() return get_fa_icon("ICON_FA_VOLUME_UP", "V") end
local function fa_power() return get_fa_icon("ICON_FA_POWER_OFF", "P") end
local function fa_user() return get_fa_icon("ICON_FA_USER", "U") end
local function fa_eye() return get_fa_icon("ICON_FA_EYE", "E") end
local function fa_eye_slash() return get_fa_icon("ICON_FA_EYE_SLASH", "E") end
local function fa_close() return get_fa_icon("ICON_FA_TIMES", "X") end
local function fa_keyboard() return get_fa_icon("ICON_FA_KEYBOARD", "K") end
local function fa_comment() return get_fa_icon("ICON_FA_COMMENT", "C") end
local function fa_cog() return get_fa_icon("ICON_FA_COG", "G") end
local function fa_users() return get_fa_icon("ICON_FA_USERS", "U") end
local function fa_check() return get_fa_icon("ICON_FA_CHECK", "+") end
local function fa_times() return get_fa_icon("ICON_FA_TIMES", "-") end
local function fa_skull() return get_fa_icon("ICON_FA_SKULL", "☠") end

-- Vehicle renderer resources
local font_flag = require("moonloader").font_flag
local cars = {
"Landstalker","Bravura","Buffalo","Linerunner","Pereniel","Sentinel","Dumper","Firetruck","Trashmaster","Stretch","Manana","Infernus","Voodoo","Pony",
"Mule","Cheetah","Ambulance","Leviathan","Moonbeam","Esperanto","Taxi","Washington","Bobcat","Mr Whoopee","BF Injection","Hunter","Premier","Enforcer",
"Securicar","Banshee","Predator","Bus","Rhino","Barracks","Hotknife","Trailer","Previon","Coach","Cabbie","Stallion","Rumpo","RC Bandit",
"Romero","Packer","Monster Truck","Admiral","Squalo","Seasparrow","Pizzaboy","Tram","Trailer","Turismo","Speeder","Reefer","Tropic","Flatbed","Yankee",
"Caddy","Solair","Berkley's RC Van","Skimmer","PCJ-600","Faggio","Freeway","RC Baron","RC Raider","Glendale","Oceanic","Sanchez","Sparrow","Patriot",
"Quad","Coastguard","Dinghy","Hermes","Sabre","Rustler","ZR-350","Walton","Regina","Comet","BMX","Burrito","Camper","Marquis","Baggage","Dozer",
"Maverick","News Chopper","Rancher","FBI Rancher","Virgo","Greenwood","Jetmax","Hotring","Sandking","Blista Compact","Police Maverick","Boxville",
"Benson","Mesa","RC Goblin","Hotring Racer","Hotring Racer","Bloodring Banger","Rancher","Super GT","Elegant","Journey","Bike","Mountain Bike","Beagle",
"Cropdust","Stunt","Tanker","RoadTrain","Nebula","Majestic","Buccaneer","Shamal","Hydra","FCR-900","NRG-500","HPV1000","Cement Truck","Tow Truck",
"Fortune","Cadrona","FBI Truck","Willard","Forklift","Tractor","Combine","Feltzer","Remington","Slamvan","Blade","Freight","Streak","Vortex",
"Vincent","Bullet","Clover","Sadler","Firetruck","Hustler","Intruder","Primo","Cargobob","Tampa","Sunrise","Merit","Utility","Nevada",
"Yosemite","Windsor","Monster Truck","Monster Truck","Uranus","Jester","Sultan","Stratum","Elegy","Raindance","RC Tiger","Flash","Tahoma",
"Savanna","Bandito","Freight","Trailer","Kart","Mower","Duneride","Sweeper","Broadway","Tornado","AT-400","DFT-30","Huntley","Stafford","BF-400",
"Newsvan","Tug","Trailer","Emperor","Wayfarer","Euros","Hotdog","Club","Trailer","Trailer","Andromada","Dodo","RC Cam","Launch","Police Car (LS)",
"Police Car (SF)","Police Car (LV)","Police Ranger","Picador","S.W.A.T. Van","Alpha","Phoenix","Glendale","Sadler","Luggage Trailer","Luggage Trailer",
"Stair Trailer","Boxville","Farm Plow","Utility Trailer"
}
local colors = {
0x000000FF,0xF5F5F5FF,0x2A77A1FF,0x840410FF,0x263739FF,0x86446EFF,0xD78E10FF,0x4C75B7FF,0xBDBEC6FF,0x5E7072FF,
0x46597AFF,0x656A79FF,0x5D7E8DFF,0x58595AFF,0xD6DAD6FF,0x9CA1A3FF,0x335F3FFF,0x730E1AFF,0x7B0A2AFF,0x9F9D94FF,
0x3B4E78FF,0x732E3EFF,0x691E3BFF,0x96918CFF,0x515459FF,0x3F3E45FF,0xA5A9A7FF,0x635C5AFF,0x3D4A68FF,0x979592FF,
0x421F21FF,0x5F272BFF,0x8494ABFF,0x767B7CFF,0x646464FF,0x5A5752FF,0x252527FF,0x2D3A35FF,0x93A396FF,0x6D7A88FF,
0x221918FF,0x6F675FFF,0x7C1C2AFF,0x5F0A15FF,0x193826FF,0x5D1B20FF,0x9D9872FF,0x7A7560FF,0x989586FF,0xADB0B0FF,
0x848988FF,0x304F45FF,0x4D6268FF,0x162248FF,0x272F4BFF,0x7D6256FF,0x9EA4ABFF,0x9C8D71FF,0x6D1822FF,0x4E6881FF,
0x9C9C98FF,0x917347FF,0x661C26FF,0x949D9FFF,0xA4A7A5FF,0x8E8C46FF,0x341A1EFF,0x6A7A8CFF,0xAAAD8EFF,0xAB988FFF,
0x851F2EFF,0x6F8297FF,0x585853FF,0x9AA790FF,0x601A23FF,0x20202CFF,0xA4A096FF,0xAA9D84FF,0x78222BFF,0x0E316DFF,
0x722A3FFF,0x7B715EFF,0x741D28FF,0x1E2E32FF,0x4D322FFF,0x7C1B44FF,0x2E5B20FF,0x395A83FF,0x6D2837FF,0xA7A28FFF,
0xAFB1B1FF,0x364155FF,0x6D6C6EFF,0x0F6A89FF,0x204B6BFF,0x2B3E57FF,0x9B9F9DFF,0x6C8495FF,0x4D8495FF,0xAE9B7FFF,
0x406C8FFF,0x1F253BFF,0xAB9276FF,0x134573FF,0x96816CFF,0x64686AFF,0x105082FF,0xA19983FF,0x385694FF,0x525661FF,
0x7F6956FF,0x8C929AFF,0x596E87FF,0x473532FF,0x44624FFF,0x730A27FF,0x223457FF,0x640D1BFF,0xA3ADC6FF,0x695853FF,
0x9B8B80FF,0x620B1CFF,0x5B5D5EFF,0x624428FF,0x731827FF,0x1B376DFF,0xEC6AAEFF,0x000000FF,
0x177517FF,0x210606FF,0x125478FF,0x452A0DFF,0x571E1EFF,0x010701FF,0x25225AFF,0x2C89AAFF,0x8A4DBDFF,0x35963AFF,
0xB7B7B7FF,0x464C8DFF,0x84888CFF,0x817867FF,0x817A26FF,0x6A506FFF,0x583E6FFF,0x8CB972FF,0x824F78FF,0x6D276AFF,
0x1E1D13FF,0x1E1306FF,0x1F2518FF,0x2C4531FF,0x1E4C99FF,0x2E5F43FF,0x1E9948FF,0x1E9999FF,0x999976FF,0x7C8499FF,
0x992E1EFF,0x2C1E08FF,0x142407FF,0x993E4DFF,0x1E4C99FF,0x198181FF,0x1A292AFF,0x16616FFF,0x1B6687FF,0x6C3F99FF,
0x481A0EFF,0x7A7399FF,0x746D99FF,0x53387EFF,0x222407FF,0x3E190CFF,0x46210EFF,0x991E1EFF,0x8D4C8DFF,0x805B80FF,
0x7B3E7EFF,0x3C1737FF,0x733517FF,0x781818FF,0x83341AFF,0x8E2F1CFF,0x7E3E53FF,0x7C6D7CFF,0x020C02FF,0x072407FF,
0x163012FF,0x16301BFF,0x642B4FFF,0x368452FF,0x999590FF,0x818D96FF,0x99991EFF,0x7F994CFF,0x839292FF,0x788222FF,
0x2B3C99FF,0x3A3A0BFF,0x8A794EFF,0x0E1F49FF,0x15371CFF,0x15273AFF,0x375775FF,0x060820FF,0x071326FF,0x20394BFF,
0x2C5089FF,0x15426CFF,0x103250FF,0x241663FF,0x692015FF,0x8C8D94FF,0x516013FF,0x090F02FF,0x8C573AFF,0x52888EFF,
0x995C52FF,0x99581EFF,0x993A63FF,0x998F4EFF,0x99311EFF,0x0D1842FF,0x521E1EFF,0x42420DFF,0x4C991EFF,0x082A1DFF,
0x96821DFF,0x197F19FF,0x3B141FFF,0x745217FF,0x893F8DFF,0x7E1A6CFF,0x0B370BFF,0x27450DFF,0x071F24FF,0x784573FF,
0x8A653AFF,0x732617FF,0x319490FF,0x56941DFF,0x59163DFF,0x1B8A2FFF,0x38160BFF,0x041804FF,0x355D8EFF,0x2E3F5BFF,
0x561A28FF,0x4E0E27FF,0x706C67FF,0x3B3E42FF,0x2E2D33FF,0x7B7E7DFF,0x4A4442FF,0x28344EFF
}

-- ClickWarp deps/state
local sampfuncs_ok, sampfuncs = pcall(require, "lib.sampfuncs")
local vkeys = require "vkeys"
local Matrix3X3 = require "matrix3x3"
local Vector3D = require "vector3d"
local keyToggle = vkeys.VK_MBUTTON
local keyApply = vkeys.VK_LBUTTON
local cursorEnabled = false
local cw_font, cw_font2 = nil, nil
local pointMarker = nil
local clickwarp_thread = nil

-- AirBrake state
local air_thread = nil
local air_pow = 0.7
local air_pow_car = 1.9
local raknet = nil
local ffi = nil
local samp_sync = nil
local function stop_air() end
local function start_air() end

-- === FONT LOADING ===
function imgui.BeforeDrawFrame()
    if fa_loaded and fa and fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        local font_path = "moonloader/resource/fonts/fa-solid-900.ttf"
        -- Try to load font, but don't fail if file doesn't exist
        local success, result = pcall(function()
            return imgui.GetIO().Fonts:AddFontFromFileTTF(font_path, 13.0, font_config, fa_glyph_ranges)
        end)
        if success and result then
            fa_font = result
            imgui.RebuildFonts()
        end
    end
    if clickwarp_enabled.v and sampfuncs_ok and not cw_font then
        cw_font = renderCreateFont("Tahoma", 10, FCR_BOLD + FCR_BORDER)
        cw_font2 = renderCreateFont("Arial", 8, FCR_ITALICS + FCR_BORDER)
    end
end

-- ClickWarp helpers
local function cw_showCursor(toggle)
    if toggle then
        sampSetCursorMode(CMODE_LOCKCAM)
    else
        sampToggleCursor(false)
    end
    cursorEnabled = toggle
end

local function cw_createPointMarker(x, y, z)
    pointMarker = createUser3dMarker(x, y, z + 0.3, 4)
end

local function cw_removePointMarker()
    if pointMarker then
        removeUser3dMarker(pointMarker)
        pointMarker = nil
    end
end

local function cw_readFloatArray(ptr, idx)
    return representIntAsFloat(readMemory(ptr + idx * 4, 4, false))
end

local function cw_writeFloatArray(ptr, idx, value)
    writeMemory(ptr + idx * 4, 4, representFloatAsInt(value), false)
end

local function cw_getVehicleRotationMatrix(car)
    local entityPtr = getCarPointer(car)
    if entityPtr ~= 0 then
        local mat = readMemory(entityPtr + 0x14, 4, false)
        if mat ~= 0 then
            local rx, ry, rz, fx, fy, fz, ux, uy, uz
            rx = cw_readFloatArray(mat, 0); ry = cw_readFloatArray(mat, 1); rz = cw_readFloatArray(mat, 2)
            fx = cw_readFloatArray(mat, 4); fy = cw_readFloatArray(mat, 5); fz = cw_readFloatArray(mat, 6)
            ux = cw_readFloatArray(mat, 8); uy = cw_readFloatArray(mat, 9); uz = cw_readFloatArray(mat, 10)
            return rx, ry, rz, fx, fy, fz, ux, uy, uz
        end
    end
end

local function cw_setVehicleRotationMatrix(car, rx, ry, rz, fx, fy, fz, ux, uy, uz)
    local entityPtr = getCarPointer(car)
    if entityPtr ~= 0 then
        local mat = readMemory(entityPtr + 0x14, 4, false)
        if mat ~= 0 then
            cw_writeFloatArray(mat, 0, rx); cw_writeFloatArray(mat, 1, ry); cw_writeFloatArray(mat, 2, rz)
            cw_writeFloatArray(mat, 4, fx); cw_writeFloatArray(mat, 5, fy); cw_writeFloatArray(mat, 6, fz)
            cw_writeFloatArray(mat, 8, ux); cw_writeFloatArray(mat, 9, uy); cw_writeFloatArray(mat, 10, uz)
        end
    end
end

local function cw_rotateCarAroundUpAxis(car, vec)
    local rx, ry, rz, fx, fy, fz, ux, uy, uz = cw_getVehicleRotationMatrix(car)
    if not rx then return end
    local mat = Matrix3X3(rx, ry, rz, fx, fy, fz, ux, uy, uz)
    local rotAxis = Vector3D(mat.up:get())
    vec:normalize(); rotAxis:normalize()
    local theta = math.acos(rotAxis:dotProduct(vec))
    if theta ~= 0 then
        rotAxis:crossProduct(vec)
        rotAxis:normalize()
        rotAxis:zeroNearZero()
        mat = mat:rotate(rotAxis, -theta)
    end
    cw_setVehicleRotationMatrix(car, mat:get())
end

local function cw_getCarFreeSeat(car)
    if doesCharExist(getDriverOfCar(car)) then
        local maxPassengers = getMaximumNumberOfPassengers(car)
        for i = 0, maxPassengers do
            if isCarPassengerSeatFree(car, i) then return i + 1 end
        end
        return nil
    else
        return 0
    end
end

local function cw_jumpIntoCar(car)
    local seat = cw_getCarFreeSeat(car)
    if not seat then return false end
    if seat == 0 then warpCharIntoCar(PLAYER_PED, car)
    else warpCharIntoCarAsPassenger(PLAYER_PED, car, seat - 1) end
    restoreCameraJumpcut()
    return true
end

local function cw_teleportPlayer(x, y, z)
    if isCharInAnyCar(PLAYER_PED) then
        setCharCoordinates(PLAYER_PED, x, y, z)
    end
    setCharCoordinatesDontResetAnim(PLAYER_PED, x, y, z)
end

local function cw_setEntityCoordinates(entityPtr, x, y, z)
    if entityPtr ~= 0 then
        local matrixPtr = readMemory(entityPtr + 0x14, 4, false)
        if matrixPtr ~= 0 then
            local posPtr = matrixPtr + 0x30
            writeMemory(posPtr + 0, 4, representFloatAsInt(x), false)
            writeMemory(posPtr + 4, 4, representFloatAsInt(y), false)
            writeMemory(posPtr + 8, 4, representFloatAsInt(z), false)
        end
    end
end

function setCharCoordinatesDontResetAnim(char, x, y, z)
    if doesCharExist(char) then
        local ptr = getCharPointer(char)
        cw_setEntityCoordinates(ptr, x, y, z)
    end
end

local function stop_clickwarp()
    clickwarp_enabled.v = false
    if clickwarp_thread and clickwarp_thread:status() ~= "dead" then
        clickwarp_thread:terminate()
    end
    clickwarp_thread = nil
    cw_showCursor(false)
    cw_removePointMarker()
end

local function start_clickwarp()
    if not sampfuncs_ok then
        sampAddChatMessage("{8c03fc}[AdminTools] {ff0000}SAMPFUNCS ar aris, ClickWarp vergamoiqmara.", -1)
        clickwarp_enabled.v = false
        return
    end
    if clickwarp_thread and clickwarp_thread:status() ~= "dead" then return end
    clickwarp_thread = lua_thread.create(function()
        while clickwarp_enabled.v do
            while isPauseMenuActive() do
                if cursorEnabled then cw_showCursor(false) end
                wait(100)
            end

            if isKeyDown(keyToggle) then
                cursorEnabled = not cursorEnabled
                cw_showCursor(cursorEnabled)
                while isKeyDown(keyToggle) do wait(80) end
            end

            if cursorEnabled then
                local mode = sampGetCursorMode()
                if mode == 0 then cw_showCursor(true) end
                local sx, sy = getCursorPos()
                local sw, sh = getScreenResolution()
                if sx >= 0 and sy >= 0 and sx < sw and sy < sh then
                    local posX, posY, posZ = convertScreenCoordsToWorld3D(sx, sy, 700.0)
                    local camX, camY, camZ = getActiveCameraCoordinates()
                    local result, colpoint = processLineOfSight(camX, camY, camZ, posX, posY, posZ, true, true, false, true, false, false, false)
                    if result and colpoint.entity ~= 0 then
                        local normal = colpoint.normal
                        local pos = Vector3D(colpoint.pos[1], colpoint.pos[2], colpoint.pos[3]) - (Vector3D(normal[1], normal[2], normal[3]) * 0.1)
                        local zOffset = normal[3] >= 0.5 and 1 or 300
                        local result2, colpoint2 = processLineOfSight(pos.x, pos.y, pos.z + zOffset, pos.x, pos.y, pos.z - 0.3, true, true, false, true, false, false, false)
                        if result2 then
                            pos = Vector3D(colpoint2.pos[1], colpoint2.pos[2], colpoint2.pos[3] + 1)
                            local curX, curY, curZ  = getCharCoordinates(PLAYER_PED)
                            local dist = getDistanceBetweenCoords3d(curX, curY, curZ, pos.x, pos.y, pos.z)
                            local hoffs = cw_font and renderGetFontDrawHeight(cw_font) or 10
                            renderFontDrawText(cw_font or font_warning, string.format("%0.2fm", dist), sx - 2, sy - 2 - hoffs, 0xEEEEEEEE)

                            local tpIntoCar = nil
                            if colpoint.entityType == 2 then
                                local car = getVehiclePointerHandle(colpoint.entity)
                                if doesVehicleExist(car) and (not isCharInAnyCar(PLAYER_PED) or storeCarCharIsInNoSave(PLAYER_PED) ~= car) then
                                    renderFontDrawText(cw_font2 or font_warning, "Hold right mouse to teleport into car", sx - 2, sy - 2 - hoffs * 2, 0xAAFFFFFF)
                                    if isKeyDown(vkeys.VK_RBUTTON) then
                                        tpIntoCar = car
                                    end
                                end
                            end

                            cw_createPointMarker(pos.x, pos.y, pos.z)

                            if isKeyDown(keyApply) then
                                if tpIntoCar then
                                    if not cw_jumpIntoCar(tpIntoCar) then
                                        cw_teleportPlayer(pos.x, pos.y, pos.z)
                                    end
                                else
                                    if isCharInAnyCar(PLAYER_PED) then
                                        local norm = Vector3D(colpoint.normal[1], colpoint.normal[2], 0)
                                        local norm2 = Vector3D(colpoint2.normal[1], colpoint2.normal[2], colpoint2.normal[3])
                                        cw_rotateCarAroundUpAxis(storeCarCharIsInNoSave(PLAYER_PED), norm2)
                                        pos = pos - norm * 1.8
                                        pos.z = pos.z - 0.8
                                    end
                                    cw_teleportPlayer(pos.x, pos.y, pos.z)
                                end
                                cw_removePointMarker()
                                while isKeyDown(keyApply) do wait(0) end
                                cw_showCursor(false)
                            end
                        end
                    end
                end
            end
            wait(0)
            cw_removePointMarker()
        end
        cw_showCursor(false)
        cw_removePointMarker()
    end)
end


-- === MAIN THREAD ===
function main()
    font_warning = renderCreateFont("Arial", 18, 5)
    repeat wait(100) until isSampAvailable()
    if not vehicle_font then
        vehicle_font = renderCreateFont("Arial", 11, font_flag.SHADOW + font_flag.BOLD)
    end

    -- Load saved settings
    input_password.v = config.main.password
    auto_az.v = config.main.auto_az
    toggle_auto_apanel.v = (config.main.password ~= "")
    for i = 1, 9 do
        reply_buffers[i].v = config.main["quick_reply"..i]
    end

    sampRegisterChatCommand("amenu", function()
        show_menu.v = true
    end)

    sampAddChatMessage("{8c03fc}[AdminTools] {ffffff}Scripti chaitvirta. Versia:. Developer: tsinsandro_", -1)

    lua_thread.create(function()
        while true do wait(50)
            if auto_report_enabled and isSampAvailable() then
                sampSendClickTextdraw(460)
            end
        end
    end)


    while true do
        wait(0)
        imgui.Process = show_menu.v or show_reply_gui.v

        -- Vehicle renderer draw (controlled by UI toggle)
        if vrender_enabled.v and vehicle_font then
            local vehs = getAllVehicles()
            for _, v in ipairs(vehs) do
                if isCarOnScreen(v) then
                    local modelId = getCarModel(v)
                    local name = cars[modelId - 399] or ("ID " .. tostring(modelId))
                    local _, vid = sampGetVehicleIdByCarHandle(v)
                    local label = string.format("%s (%d)", name, vid or 0)
                    local clr, _ = getCarColours(v)
                    local cx, cy, cz = getCarCoordinates(v)
                    local sx, sy = convert3DCoordsToScreen(cx, cy, cz)
                    if sx and sy then
                        local len = renderGetFontDrawTextLength(vehicle_font, label, true)
                        local height = renderGetFontDrawHeight(vehicle_font)
                        local textcolor = 0xFF00B811
                        if getCarDoorLockStatus(v) == 2 then
                            textcolor = 0xFFEC0000
                        end
                        renderFontDrawText(vehicle_font, label, sx - (len + 5 + 18) / 2, sy - (height + 7 + 14) / 2, textcolor, true)
                        renderDrawBox(sx + (len + 5 - 18) / 2, sy - (7 + 14) / 2 - 9, 18, 18, 0xFFFFFFFF)
                        local carColor = colors[(clr or 0) + 1] or 0xFFFFFFFF
                        renderDrawBox(sx + (len + 5 - 18) / 2 + 2, sy - (7 + 14) / 2 - 7, 14, 14, 0xFF000000 + carColor / 0x100)
                        local healthbox = len + 5 + 18 + 8
                        local healthbox2 = healthbox * (getCarHealth(v) / 1000)
                        renderDrawBox(sx - healthbox / 2 - 1, sy + (height + 7 - 14) / 2, healthbox + 2, 14, 0xFF000000)
                        renderDrawBox(sx - healthbox / 2, sy + (height + 7 - 14) / 2 + 1, healthbox, 12, 0xFF0084DF)
                        renderDrawBox(sx - healthbox / 2, sy + (height + 7 - 14) / 2 + 1, healthbox2, 12, 0xFF005C9B)
                    end
                end
            end
        end

        -- AirBrake activation: hold SHIFT to engage when feature toggle is ON
        if air_enabled.v and isKeyDown(vkeys.VK_SHIFT) then
            if not air_thread or air_thread:status() == "dead" then
                start_air()
            end
        else
            if air_thread and air_thread:status() ~= "dead" then
                stop_air()
            end
        end
    end
end

-- === GUI ===
function imgui.OnDrawFrame()
    -- === MAIN MENU ===
    if show_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(1000, 700), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowPos(imgui.ImVec2(100, 100), imgui.Cond.FirstUseEver)
        
        -- Set dark theme colors
        local style = imgui.GetStyle()
        -- Only set colors that exist in this imgui version (removed ChildBg as it doesn't exist)
        style.Colors[imgui.Col.WindowBg] = darker_bg
        style.Colors[imgui.Col.Button] = purple_dark
        style.Colors[imgui.Col.ButtonHovered] = purple_color
        style.Colors[imgui.Col.ButtonActive] = purple_dark
        style.Colors[imgui.Col.FrameBg] = dark_bg
        style.Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.25, 0.25, 0.25, 1.0)
        style.Colors[imgui.Col.FrameBgActive] = purple_dark
        style.Colors[imgui.Col.Header] = purple_dark
        style.Colors[imgui.Col.HeaderHovered] = purple_color
        style.Colors[imgui.Col.HeaderActive] = purple_color
        style.Colors[imgui.Col.Text] = imgui.ImVec4(1.0, 1.0, 1.0, 1.0)
        style.Colors[imgui.Col.Border] = imgui.ImVec4(0.3, 0.3, 0.3, 1.0)
        
        imgui.Begin("Admin Tools", show_menu, imgui.WindowFlags.NoCollapse)
        
        -- Toggle renderer (shared)
        local function DrawToggle(label, toggle_var, tooltip)
            imgui.PushID(label)
            local is_on = toggle_var.v
            local toggle_size = imgui.ImVec2(40, 20)
            
            local cursor_pos = imgui.GetCursorScreenPos()
            local draw_list = imgui.GetWindowDrawList()
            local toggle_color = is_on and purple_color or imgui.ImVec4(0.3, 0.3, 0.3, 1.0)
            
            draw_list:AddRectFilled(cursor_pos, imgui.ImVec2(cursor_pos.x + toggle_size.x, cursor_pos.y + toggle_size.y), imgui.GetColorU32(toggle_color), 10.0)
            local circle_x = is_on and (cursor_pos.x + toggle_size.x - 10) or (cursor_pos.x + 10)
            draw_list:AddCircleFilled(imgui.ImVec2(circle_x, cursor_pos.y + toggle_size.y / 2), 8, imgui.GetColorU32(imgui.ImVec4(1.0, 1.0, 1.0, 1.0)))
            
            if imgui.InvisibleButton("##toggle", toggle_size) then
                toggle_var.v = not toggle_var.v
            end
            
            imgui.SameLine()
            imgui.Text(label)
            
            if tooltip then
                imgui.SameLine()
                imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), "?")
                if imgui.IsItemHovered() then
                    imgui.SetTooltip(tooltip)
                end
            end
            
            imgui.PopID()
            imgui.Spacing()
        end
        
        local window_size = imgui.GetWindowSize()
        
        -- === SIDEBAR ===
        imgui.BeginChild("Sidebar", imgui.ImVec2(sidebar_width, window_size.y - 40), true)
        
        -- Logo and Title
        imgui.SetCursorPos(imgui.ImVec2(10, 10))
        imgui.TextColored(purple_color, "Admin Tools")
        imgui.Separator()
        
        -- Top icons
        imgui.SetCursorPos(imgui.ImVec2(10, 50))
        if imgui.Button(fa_power(), imgui.ImVec2(30, 30)) then
            -- Power button (placeholder)
        end
        imgui.SameLine()
        if imgui.Button(fa_save(), imgui.ImVec2(30, 30)) then
            -- Save button
            if toggle_auto_apanel.v then
                config.main.password = input_password.v
            else
                config.main.password = ""
            end
            config.main.auto_az = auto_az.v
            for i = 1, 9 do
                config.main["quick_reply"..i] = reply_buffers[i].v
            end
            inicfg.save(config, config_file)
            sampAddChatMessage("{8c03fc}[AdminTools] {ffffff}Configi shenaxulia!", -1)
        end
        imgui.SameLine()
        if imgui.Button(fa_bell(), imgui.ImVec2(30, 30)) then
            -- Bell button (placeholder)
        end
        imgui.SameLine()
        if imgui.Button(fa_question(), imgui.ImVec2(30, 30)) then
            -- Help button (placeholder)
        end
        imgui.SameLine()
        if imgui.Button(fa_volume(), imgui.ImVec2(30, 30)) then
            -- Speaker button (placeholder)
        end
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        
        -- Navigation Menu
        if imgui.Button(fa_home() .. " Mtavari", imgui.ImVec2(sidebar_width - 20, 40)) then
            current_tab.v = 0
        end
        if imgui.Button(fa_skull() .. " Admin Soft", imgui.ImVec2(sidebar_width - 20, 40)) then
            current_tab.v = 1
        end
        
        imgui.EndChild()
        
        -- === MAIN CONTENT AREA ===
        imgui.SameLine()
        imgui.BeginChild("MainContent", imgui.ImVec2(window_size.x - sidebar_width - 30, window_size.y - 40), true)
        
        -- Close button (top right)
        local content_size = imgui.GetContentRegionAvail()
        imgui.SetCursorPos(imgui.ImVec2(content_size.x - 30, 5))
        if imgui.Button(fa_close(), imgui.ImVec2(25, 25)) then
            show_menu.v = false
        end
        
        if current_tab.v == 0 then
            -- === TOP PANEL: ACCOUNT INFO ===
            imgui.SetCursorPos(imgui.ImVec2(10, 10))
            imgui.TextColored(purple_color, "Mtavari menu")
            imgui.Spacing()
            
            imgui.BeginChild("MainInfo", imgui.ImVec2(content_size.x - 20, 120), true)
            imgui.Text("!!! Scripti aris betashi !!!\nFor ED:RP\nDeveloper: tsinsandro_")
            imgui.Spacing()
            imgui.EndChild()
            
            imgui.Spacing()
            
            -- === BOTTOM PANEL: SPLIT VIEW ===
            local bottom_height = content_size.y - 150
            imgui.BeginChild("BottomPanel", imgui.ImVec2(content_size.x - 20, bottom_height), true)
            
            -- Left: Useful Functions
            imgui.BeginChild("UsefulFunctions", imgui.ImVec2((content_size.x - 40) / 2, bottom_height - 20), true)
            imgui.Text("Mtavari funqciebi:")
            imgui.Spacing()
            
            -- Auto /apanel with password input (ORIGINAL FEATURE)
            DrawToggle("Auto /аlogin", toggle_auto_apanel)
            if toggle_auto_apanel.v then
                imgui.PushItemWidth((content_size.x - 40) / 2 - 60)
                local flags = imgui.InputTextFlags.Password
                if password_visible.v then flags = 0 end
                imgui.InputText("##password", input_password, flags)
                imgui.PopItemWidth()
                imgui.SameLine()
                if imgui.Button(password_visible.v and fa_eye() or fa_eye_slash(), imgui.ImVec2(25, 20)) then
                    password_visible.v = not password_visible.v
                end
                imgui.Spacing()
            end
            
            -- Update password when toggle is enabled
            if toggle_auto_apanel.v and input_password.v ~= "" then
                config.main.password = input_password.v
            elseif not toggle_auto_apanel.v then
                config.main.password = ""
            end
            
            -- Auto /az after login (ORIGINAL FEATURE)
            DrawToggle("Spawni /az'shi", auto_az)
            
            -- Auto Report (ORIGINAL FEATURE)
            DrawToggle("Auto Report", auto_report, u8"Tavisit igebs reports rodesac aris gaxsnili H menu")
            auto_report_enabled = auto_report.v

            DrawToggle("Vehicle renderer", vrender_enabled, "Show vehicle info in world")
            
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            
            
            -- Quick Reply Phrases (ORIGINAL FEATURE)
            imgui.Text("Swrafi pasuxis config:")
            for i = 1, 9 do
                imgui.InputText("Reply "..i, reply_buffers[i])
            end
            
            imgui.EndChild()
            
            -- Right: Hotkeys
            imgui.SameLine()
            imgui.BeginChild("Hotkeys", imgui.ImVec2((content_size.x - 40) / 2, bottom_height - 20), true)
            imgui.Text("Hotkeys:")
            imgui.Spacing()
            
            local hotkeys = {
                {key = "", action = "MALE DAEMATEBA"},
                {key = "F4", action = "MALE DAEMATE"},
                {key = "Context Menu", action = "MALE DAEMATE"},
                {key = "F", action = "MALE DAEMATE"},
                {key = "Ctrl + Home", action = "MALE DAEMATE"},
                {key = "Ar aris", action = "MALE DAEMATE"}
            }
            
            for _, hk in ipairs(hotkeys) do
                imgui.TextColored(purple_color, hk.key .. "  -  " .. hk.action)
                imgui.Spacing()
            end
            
            imgui.EndChild()
            
            imgui.EndChild() -- BottomPanel
        else
            -- Admin Soft tab
            imgui.SetCursorPos(imgui.ImVec2(10, 10))
            imgui.TextColored(purple_color, fa_skull() .. " Admin Soft")
            imgui.Spacing()
            
            imgui.BeginChild("AdminSoft", imgui.ImVec2(content_size.x - 20, content_size.y - 40), true)
            imgui.Text("Invisibility")
            imgui.Spacing()
            DrawToggle("Enable invisibility", invis_enabled, "Gxdit uxilavs sxva motamasheebistvis.")
            if invis_enabled.v then
                imgui.TextColored(purple_color, "Invisibility is ON")
            else
                imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1.0), "Invisibility is OFF")
            end
            imgui.Spacing()
            DrawToggle("Enable ClickWarp", clickwarp_enabled, "Middle click cursor, left click warp. Hold right mouse to enter vehicle.")
            if clickwarp_enabled.v then
                start_clickwarp()
                imgui.TextColored(purple_color, "ClickWarp is ON")
            else
                stop_clickwarp()
                imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1.0), "ClickWarp is OFF")
            end
            imgui.Spacing()
            DrawToggle("Enable AirBrake", air_enabled, "Air movement control (on-foot/in-car)")
            if air_enabled.v then
                start_air()
                imgui.TextColored(purple_color, "AirBrake is ON")
            else
                stop_air()
                imgui.TextColored(imgui.ImVec4(0.7,0.7,0.7,1.0), "AirBrake is OFF")
            end
            imgui.Text(string.format("On-foot speed: %.3f | In-car speed: %.3f", air_pow, air_pow_car))
            imgui.Spacing()
            imgui.EndChild()
        end
        
        imgui.EndChild() -- MainContent
        
        imgui.End()
    end

    -- === QUICK REPLY WINDOW ===
    if show_reply_gui.v then
        imgui.SetNextWindowPos(imgui.ImVec2(100, 600), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.FirstUseEver)
        
        -- Apply dark theme to quick reply window
        local style = imgui.GetStyle()
        style.Colors[imgui.Col.WindowBg] = darker_bg
        style.Colors[imgui.Col.Button] = purple_dark
        style.Colors[imgui.Col.ButtonHovered] = purple_color
        style.Colors[imgui.Col.ButtonActive] = purple_dark
        
        imgui.Begin("Quick Reply", show_reply_gui, imgui.WindowFlags.NoCollapse)
        imgui.TextColored(purple_color, "Quick Replies:")

        -- 3x3 grid
        for row = 1, 3 do
            for col = 1, 3 do
                local idx = (row - 1) * 3 + col
                if imgui.Button(reply_buffers[idx].v, imgui.ImVec2(120, 30)) then
                    injectQuickReply(reply_buffers[idx].v)
                end
                if col < 3 then imgui.SameLine() end
            end
        end

        imgui.Separator()

        -- Extra buttons
        if imgui.Button("Gadacema", imgui.ImVec2(180, 30)) then
            if lastReportReason ~= "" and lastReportPlayerId then
                local cmd = string.format("/a [REPORT] %s %d", lastReportReason, lastReportPlayerId)
                sampSendChat(cmd)
                sampAddChatMessage("{00FF00}{8c03fc}[AdminTools] {ffffff}Gaigzavna -> "..cmd, -1)
            else
                sampAddChatMessage("{FF0000}{8c03fc}[AdminTools] {ffffff}Cannot execute transfer, no data.", -1)
            end
        end

        imgui.SameLine()

        if imgui.Button("Recon", imgui.ImVec2(100, 30)) then
            if lastReportPlayerId then
                local cmd = string.format("/re %d", lastReportPlayerId)
                sampSendChat(cmd)
                sampAddChatMessage("{8c03fc}[AdminTools] {ffffff}Sent -> "..cmd, -1)
            else
                sampAddChatMessage("{8c03fc}[AdminTools] {ffffff}Cannot execute recon, no ID.", -1)
            end
        end

        imgui.End()
    end
end

-- === DIALOG HANDLING ===
function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if title:lower():find("admin panel") then
        lua_thread.create(function()
            wait(200)
            if config.main.password ~= "" then
                sampSendDialogResponse(dialogId, 1, 0, config.main.password)
                sampCloseCurrentDialogWithButton(1)
                sampAddChatMessage("{00FF00}{8c03fc}[AdminTools] {ffffff}Logged in automatically.", -1)
                if config.main.auto_az then
                    wait(1000)
                    sampSendChat("/az")
                    sampAddChatMessage("{00FF00}{8c03fc}[AdminTools] {ffffff}Gashvebulia /az.", -1)
                end
            else
                sampAddChatMessage("{FF0000}{8c03fc}[AdminTools] {ffffff}Paroli ar aris shenaxuli! Gamoiyenet /amenu.", -1)
            end
        end)
    end

    if title:lower():find("report") then
        lastReportDialogId = dialogId
        lastReportReason = text or ""
        -- Try to extract ID from title like "Report: [Name] (ID)"
        local id = title:match("%((%d+)%)")
        if id then
            lastReportPlayerId = tonumber(id)
        else
            lastReportPlayerId = nil
        end
        show_reply_gui.v = true
    end
end

function sampev.onDialogResponse(dialogId, button, list, input)
    if dialogId == lastReportDialogId then
        show_reply_gui.v = false
        lastReportDialogId = nil
        lastReportPlayerId = nil
        lastReportReason = ""
    end
end

function injectQuickReply(text)
    if lastReportDialogId then
        sampSendDialogResponse(lastReportDialogId, 1, 0, text)
        sampCloseCurrentDialogWithButton(1)
        show_reply_gui.v = false
    end
end

-- Invisibility sync hook
function sampev.onSendPlayerSync(data)
    if invis_enabled.v then
        local px, py, pz = getCharCoordinates(PLAYER_PED)
        data.position.x = px + 5
        data.position.y = py + 5
        data.position.z = pz - 15
    end
end

-- === AIRBRAKE ===
local function air_jitter(v)
    return v + tonumber("0.0000" .. math.random(9))
end

local function air_apply_freeze(state)
    freezeCharPosition(PLAYER_PED, state)
    if not isCharInAnyCar(PLAYER_PED) then
        setCharCollision(PLAYER_PED, not state)
    end
end

local function stop_air()
    air_enabled.v = false
    if air_thread and air_thread:status() ~= "dead" then
        air_thread:terminate()
    end
    air_thread = nil
    air_apply_freeze(false)
end

local function start_air()
    if not sampfuncs_ok then
        sampAddChatMessage("{8c03fc}[AdminTools] {ff0000}SAMPFUNCS error.", -1)
        air_enabled.v = false
        return
    end
    if air_thread and air_thread:status() ~= "dead" then return end
    air_apply_freeze(true)
    air_thread = lua_thread.create(function()
        while air_enabled.v do
            if isCharInAnyCar(PLAYER_PED) then
                air_car_step()
            else
                air_onfoot_step()
            end
            wait(0)
        end
        air_apply_freeze(false)
    end)
end

local function ensure_raknet()
    if not raknet or not ffi or not samp_sync then
        ffi = require("ffi")
        raknet = require("samp.raknet")
        samp_sync = require("samp.synchronization")
    end
end

local function samp_create_sync_data_air(sync_type, copy_from_player)
    ensure_raknet()
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    if copy_from_player == nil then copy_from_player = true end
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    return setmetatable({send = func_send, data = data}, {
        __index = function(t, index) return data[index] end,
        __newindex = function(t, index, value) data[index] = value end
    })
end

local function air_onfoot_step()
    if isKeyDown(1) then
        air_pow = air_pow + 0.001
        printStringNow("~b~ speed +"..air_pow, 1000)
    elseif isKeyDown(2) then
        air_pow = air_pow - 0.001
        if air_pow < 0 then air_pow = 0 end
        printStringNow("~b~ speed -"..air_pow, 1000)
    end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local x1, y1, z1 = getActiveCameraCoordinates()
    local head = math.rad(getHeadingFromVector2d(x - x1, y - y1))
    if isKeyDown(87) then
        x = x - math.sin(-head + 3.14) * air_pow
        y = y - math.cos(-head + 3.14) * air_pow
    elseif isKeyDown(83) then
        x = x + math.sin(-head + 3.14) * air_pow
        y = y + math.cos(-head + 3.14) * air_pow
    end
    if isKeyDown(16) then
        z = z - air_pow / 2.2
    elseif isKeyDown(32) then
        z = z + air_pow / 2.2
    end
    local sync = samp_create_sync_data_air("player")
    sync.position = {air_jitter(x), air_jitter(y), air_jitter(z - 1)}
    sync.moveSpeed = {air_jitter(0), air_jitter(0), air_jitter(0)}
    local x2, y2, z2 = getCharCoordinates(PLAYER_PED)
    if x ~= x2 or y ~= y2 or z ~= z2 then
        sync.moveSpeed = {air_jitter(0.09), air_jitter(0.091), air_jitter(0.071)}
    end
    sync.send()
    setCharHeading(PLAYER_PED, math.deg(head))
    setCharCoordinates(PLAYER_PED, x, y, z - 1)
end

local function air_car_step()
    local car = storeCarCharIsInNoSave(PLAYER_PED)
    if car == 0 then return end
    if isKeyDown(1) then
        air_pow_car = air_pow_car + 0.001
        printStringNow("~b~ speed +"..air_pow_car, 1000)
    elseif isKeyDown(2) then
        air_pow_car = air_pow_car - 0.001
        if air_pow_car < 0 then air_pow_car = 0 end
        printStringNow("~b~ speed -"..air_pow_car, 1000)
    end
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local x1, y1, z1 = getActiveCameraCoordinates()
    local head = math.rad(getHeadingFromVector2d(x - x1, y - y1))
    if isKeyDown(87) then
        x = x - math.sin(-head + 3.14) * air_pow_car
        y = y - math.cos(-head + 3.14) * air_pow_car
    elseif isKeyDown(83) then
        x = x + math.sin(-head + 3.14) * air_pow_car
        y = y + math.cos(-head + 3.14) * air_pow_car
    end
    if isKeyDown(16) then
        z = z - air_pow_car / 2.5
    elseif isKeyDown(32) then
        z = z + air_pow_car / 1.9
    end
    local sync = samp_create_sync_data_air("vehicle")
    sync.position = {air_jitter(x), air_jitter(y), air_jitter(z)}
    sync.moveSpeed = {air_jitter(0), air_jitter(0), air_jitter(0)}
    local x2, y2, z2 = getCharCoordinates(PLAYER_PED)
    if x ~= x2 or y ~= y2 or z ~= z2 then
        sync.moveSpeed = {air_jitter(0.05), air_jitter(0.05), air_jitter(0.05)}
    end
    sync.send()
    setCharHeading(PLAYER_PED, math.deg(head))
    setCharCoordinates(PLAYER_PED, x, y, z - 1.2)
end

local function stop_air()
    air_enabled.v = false
    if air_thread and air_thread:status() ~= "dead" then
        air_thread:terminate()
    end
    air_thread = nil
    air_apply_freeze(false)
end

local function start_air()
    if not sampfuncs_ok then
        sampAddChatMessage("{8c03fc}[AdminTools] {ff0000}SAMPFUNCS error.", -1)
        air_enabled.v = false
        return
    end
    if air_thread and air_thread:status() ~= "dead" then return end
    air_apply_freeze(true)
    air_thread = lua_thread.create(function()
        while air_enabled.v do
            if isCharInAnyCar(PLAYER_PED) then
                air_car_step()
            else
                air_onfoot_step()
            end
            wait(0)
        end
        air_apply_freeze(false)
    end)
end

function sampev.onShowChat(color, message)
    if message:find("Warning »") then
        warningDisplayTime = os.clock()
    end
end
