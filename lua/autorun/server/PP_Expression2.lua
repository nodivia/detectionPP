-- Adding a serializer to E2 to require all entity references to require PP
timer.Create("PP_Expression2", 1, 0, function()
    if WireLib then
        local GetOwner = WireLib.GetOwner
        local Compiler = E2Lib.Compiler

        function Compiler:Evaluate(args, index)
            local ex, tp = self:EvaluateStatement(args, index)

            if tp == "" then
                self:Error("Function has no return value (void), cannot be part of expression or assigned", args[index + 2])
            end

            if self:HasOperator(args, "serializer", {tp}) then
                ex = {self:GetOperator(args, "serializer", {tp})[1], ex}
            end

            return ex, tp
        end

        registerOperator("serializer", "e", "e", function(self, args)
            local op1  = args[2]
            local rv1  = op1[1](self, op1)
            local Type = type(rv1)

            if Type == "Entity" or Type == "Vehicle" then -- Players can only reference entities they have PP with
                if not GetOwner(rv1) or rv1:CPPICanTool(GetOwner(self.entity)) then
                    return rv1
                else
                    return nil
                end
            elseif Type == "Player" then -- Players can reference themselves and players in vehicles they own
                if GetOwner(self.entity) == rv1 then
                    return rv1
                elseif rv1:InVehicle() and GetOwner(rv1:GetVehicle()) == GetOwner(self.entity) then
                    return rv1
                else
                    return nil
                end
            else
                return rv1
            end
        end)

        timer.Remove("PP_Expression2")
    end
end)