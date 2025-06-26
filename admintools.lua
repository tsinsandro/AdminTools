script_name("Admin Tools")
script_author("tsinsandro_")

require "lib.moonloader"
local inicfg = require "inicfg"
local sampev = require "lib.samp.events"

local imgui = require "imgui"
local encoding = require "encoding"
encoding.default = "CP1251"
u8 = encoding.UTF8
local auto_report = imgui.ImBool(false)
local auto_report_enabled = false
local script_version = "1.0.1" -- Change this in every new GitHub release
local update_url = "https://raw.githubusercontent.com/tsinsandro/AdminTools/main/admintools.lua"
local version_check_url = "https://raw.githubusercontent.com/tsinsandro/AdminTools/main/version.txt"


-- === CONFIG ===
local warningDisplayTime = 0
local warningDuration = 5 -- seconds to show the warning
local font_warning
local config_file = "admin_tools.ini"
local config = inicfg.load({
    main = {
        password = "",
        auto_az = false,
        quick_reply1 = "Ok",
        quick_reply2 = "Use /report properly",
        quick_reply3 = "Wait please",
        quick_reply4 = "Handled",
        quick_reply5 = "No rule broken",
        quick_reply6 = "Warned",
        quick_reply7 = "Flip your car",
        quick_reply8 = "Read server rules",
        quick_reply9 = "Solved"
    }
}, config_file)

-- === VARIABLES ===
local show_menu = imgui.ImBool(false)
local show_reply_gui = imgui.ImBool(false)
local input_password = imgui.ImBuffer(256)
local auto_az = imgui.ImBool(config.main.auto_az)
local reply_buffers = {}
for i = 1, 9 do
    reply_buffers[i] = imgui.ImBuffer(256)
end

local lastReportDialogId = nil
local lastReportPlayerId = nil
local lastReportReason = ""

-- === MAIN THREAD ===
function main()
    font_warning = renderCreateFont("Arial", 18, 5)
    repeat wait(100) until isSampAvailable()

    -- Load saved settings
    input_password.v = config.main.password
    auto_az.v = config.main.auto_az
    for i = 1, 9 do
        reply_buffers[i].v = config.main["quick_reply"..i]
    end

    sampRegisterChatCommand("amenu", function()
        show_menu.v = not show_menu.v
    end)

    sampAddChatMessage("{00FF00}Admin Tools loaded. Use /amenu to open the menu.", -1)

    lua_thread.create(function()
    wait(1000)
    local temp_path = os.tmpname()
    downloadUrlToFile(version_check_url, temp_path, function(_, success)
        if success then
            local f = io.open(temp_path, "r")
            if f then
                local latest_version = f:read("*l")
                f:close()

                if latest_version and latest_version ~= script_version then
                    sampAddChatMessage("{FFFF00}[Admin Tools] Update found: " .. latest_version .. " (current: " .. script_version .. ")", -1)
                    sampAddChatMessage("{FFFF00}[Admin Tools] Downloading update to 'admintools_update.lua'...", -1)

                    local save_path = getWorkingDirectory() .. "\\admintools_update.lua"
                    downloadUrlToFile(update_url, save_path, function(_, ok)
                        if ok then
                            sampAddChatMessage("{00FF00}[Admin Tools] Update downloaded successfully!", -1)
                            sampAddChatMessage("{00FF00}[Admin Tools] Please exit the game and rename 'admintools_update.lua' to 'admintools.lua'.", -1)
                        else
                            sampAddChatMessage("{FF0000}[Admin Tools] Update download failed.", -1)
                        end
                    end)
                else
                    sampAddChatMessage("{00FF00}[Admin Tools] You are using the latest version.", -1)
                end
            else
                sampAddChatMessage("{FF0000}[Admin Tools] Failed to read version info.", -1)
            end
        else
            sampAddChatMessage("{FF0000}[Admin Tools] Could not connect to GitHub.", -1)
        end
    end)
end)

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
    end
end

-- === GUI ===
function imgui.OnDrawFrame()
    -- === MAIN MENU ===
    if show_menu.v then
        imgui.SetNextWindowSize(imgui.ImVec2(450, 400), imgui.Cond.FirstUseEver)
        imgui.Begin("Admin Tools", show_menu)

        -- === TOOLS ===
        if imgui.CollapsingHeader("Tools") then
            imgui.Text("Admin Panel Password:")
            imgui.InputText("##password", input_password, imgui.InputTextFlags.Password)
            imgui.Checkbox("Auto /az after login", auto_az)

            imgui.Separator()
            imgui.Text("Quick Reply Phrases:")
            for i = 1, 9 do
                imgui.InputText("Reply "..i, reply_buffers[i])
            end

            if imgui.Button("Save Settings") then
                config.main.password = input_password.v
                config.main.auto_az = auto_az.v
                for i = 1, 9 do
                    config.main["quick_reply"..i] = reply_buffers[i].v
                end
                inicfg.save(config, config_file)
                sampAddChatMessage("{00FF00}Admin Tools: Settings saved!", -1)
            end
        end


                -- === AUTO REPORT ===
        -- === AUTO REPORT ===
        if imgui.CollapsingHeader("Auto Report") then
            imgui.Checkbox("Enable Auto Report (Tavisit igebs reports rodesac aris gaxsnili H menu)", auto_report)
            auto_report_enabled = auto_report.v
            imgui.TextColored(imgui.ImVec4(1, 0.3, 0.3, 1), u8"SHEIDZLEBA IYOS AKRDZALULI. Sheekitxet Chiefs an D.Chiefs")
        end


        -- === INFO ===
        if imgui.CollapsingHeader("Info") then
            imgui.Text("Admin Tools by tsinsandro_")
            imgui.Text("For ED:RP")
            imgui.Text("proeqti vrceldeba MIT licenziit")
        end

        imgui.End()
    end

    -- === QUICK REPLY WINDOW ===
    if show_reply_gui.v then
        imgui.SetNextWindowPos(imgui.ImVec2(100, 600), imgui.Cond.FirstUseEver)
        imgui.Begin("Quick Reply", show_reply_gui, imgui.WindowFlags.AlwaysAutoResize)
        imgui.Text("Quick Replies:")

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
                sampAddChatMessage("{00FF00}Admin Tools: Sent -> "..cmd, -1)
            else
                sampAddChatMessage("{FF0000}Admin Tools: Cannot execute transfer, no data.", -1)
            end
        end

        imgui.SameLine()

        if imgui.Button("Recon", imgui.ImVec2(100, 30)) then
            if lastReportPlayerId then
                local cmd = string.format("/re %d", lastReportPlayerId)
                sampSendChat(cmd)
                sampAddChatMessage("{00FF00}Admin Tools: Sent -> "..cmd, -1)
            else
                sampAddChatMessage("{FF0000}Admin Tools: Cannot execute recon, no ID.", -1)
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
                sampAddChatMessage("{00FF00}Admin Tools: Logged in automatically.", -1)
                if config.main.auto_az then
                    wait(1000)
                    sampSendChat("/az")
                    sampAddChatMessage("{00FF00}Admin Tools: Sent /az.", -1)
                end
            else
                sampAddChatMessage("{FF0000}Admin Tools: No password saved! Use /amenu.", -1)
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
function sampev.onShowChat(color, message)
    if message:find("Warning »") then
        warningDisplayTime = os.clock()
    end
end
