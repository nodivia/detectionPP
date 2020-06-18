-- Adding a serializer to E2 to require all entity references to require PP
timer.Create("PP_Expression2", 1, 0, function()
    if WireLib then
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
                return rv1:CPPICanTool(self.entity:CPPIGetOwner()) and rv1 or nil
            elseif Type == "Player" then -- Players can reference themselves
                return self.entity:CPPIGetOwner() == rv1 and rv1 or nil
            else
                return rv1
            end
        end)

        timer.Remove("PP_Expression2")
    end
end)