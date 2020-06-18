timer.Create("PP_WireOutputs", 1, 0, function()
    if WireLib then
        local GetOwner = WireLib.GetOwner

        do -- Hijack Wiremod Entity and Array outputs and add a PP check
            TrigOut = TrigOut or WireLib.TriggerOutput

            function WireLib.TriggerOutput(Ent, OutputName, Value, Iterate)
                local Type = type(Value)

                if (Type == "Entity" or Type == "Vehicle") and IsValid(Value) then
                    if GetOwner(Value) and not Value:CPPICanTool(GetOwner(Ent)) then
                        Value = nil
                    end
                elseif Type == "Player" then
                    if GetOwner(Ent) ~= Value then
                        Value = nil
                    end
                elseif Type == "table" then
                    local Owner = GetOwner(Ent)

                    for K, V in pairs(Value) do -- This makes me feel bad. I'm sorry. 
                        local Type = type(V)

                        if (Type == "Entity" or Type == "Vehicle") and not V:CPPICanTool(Owner) then
                            Value[K] = nil
                        elseif Type == "Player" then
                            if V:InVehicle() and GetOwner(V:GetVehicle()) ~= Owner or Owner ~= V  then
                                Value[K] = nil
                            end
                        end
                    end
                end

                TrigOut(Ent, OutputName, Value, Iterate)
            end

            Wire_TriggerOutput = WireLib.TriggerOutput
        end

        do -- Override the linking/targeting behavior of Beacon Sensors combined with Target Finders
            local ORIGIN = Vector(0, 0, 0)

            local function GetBeaconPos(self, sensor)
                local ch = 1
                if (sensor.Inputs) and (sensor.Inputs.Target.SrcId) then
                    ch = tonumber(sensor.Inputs.Target.SrcId)
                end

                if self.SelectedTargets[ch] then
                    if (not self.SelectedTargets[ch]:IsValid()) then
                        self.SelectedTargets[ch] = nil
                        Wire_TriggerOutput(self, tostring(ch), 0)
                        return sensor:GetPos()
                    end

                    local Tgt = self.SelectedTargets[ch]
                    return Tgt:CPPICanTool(GetOwner(self)) and Tgt:GetPos() or ORIGIN -- This is the override
                end

                return sensor:GetPos()
            end

            hook.Add("OnEntityCreated", "PP_TargetFinder", function(Ent) -- Replace the GetBeaconPos func on Target Finders with our own
                if Ent:GetClass() == "gmod_wire_target_finder" then
                    Ent.GetBeaconPos = GetBeaconPos
                end
            end)
        end

        timer.Remove("PP_WireOutputs")
    end
end)