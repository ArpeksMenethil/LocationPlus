local LPS = _G.ArpeksLPS and _G.ArpeksLPS.LPS
if not LPS then return end
local L = LPS.L

--- Возвращает вкладку "Profiles" дерева настроек (внутренний формат дерева настроек).
function LPS.Options.BuildTree.tabs.profiles()
    return {
        name = L.PROFILES,
        order = 90,
        args = {
            currentGroup = {
                order = 1,
                name = L.PROFILES,
                args = {
                    selectProfile = {
                        order = 1,
                        type = "select",
                        name = L.SELECT_PROFILE,
                        desc = L.SELECT_PROFILE_DESC,
                        values = function()
                            if not (LPS.db and LPS.db.GetProfilesList) then return {} end
                            local items = {}
                            for _, name in ipairs(LPS.db:GetProfilesList()) do
                                items[#items + 1] = { value = name, text = name }
                            end
                            return items
                        end,
                        get = function()
                            return LPS.db and LPS.db:GetCurrentProfile() or "Default"
                        end,
                        set = function(_, v)
                            if LPS.db and LPS.db.SetProfile then
                                LPS.db:SetProfile(v)
                            end
                        end,
                    },
                    copyFrom = {
                        order = 2,
                        type = "select",
                        name = L.COPY_FROM,
                        desc = L.COPY_FROM_DESC,
                        values = function()
                            if not (LPS.db and LPS.db.GetProfilesList) then return {} end
                            local items = {}
                            for _, name in ipairs(LPS.db:GetProfilesList()) do
                                items[#items + 1] = { value = name, text = name }
                            end
                            return items
                        end,
                        get = function() return nil end,
                        set = function(_, v)
                            if LPS.db and LPS.db.CopyProfileFrom and v then
                                LPS.db:CopyProfileFrom(v)
                            end
                        end,
                    },
                    resetProfile = {
                        order = 3,
                        type = "execute",
                        name = L.RESET_PROFILE,
                        desc = L.RESET_PROFILE_DESC,
                        func = function()
                            if LPS.db and LPS.db.ResetProfile then
                                LPS.db:ResetProfile()
                            end
                        end,
                    },
                    deleteProfile = {
                        order = 4,
                        type = "execute",
                        name = L.DELETE_PROFILE,
                        desc = L.DELETE_PROFILE_DESC,
                        func = function()
                            if not (LPS.db and LPS.db.DeleteProfile) then return end
                            local cur = LPS.db:GetCurrentProfile()
                            if cur ~= "Default" then
                                LPS.db:DeleteProfile(cur)
                            end
                        end,
                    },
                },
            },
        },
    }
end
