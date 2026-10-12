-- Clover Studios
-- Made by Lucille

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Settings = {
	ExemptGroupId = 5117501; -- what group is exempt from anticheat
	ExamptRankInt = 11; -- rank exempt from anticheat
}

local TrackedCharacters = {}
local Anticheat = {}
local Visuals = {}

local function VisualizeHitDetection(pointA,pointB,hit) -- debug
	local line = Instance.new("Part")
	line.Parent = game.Workspace.Effects
	line.Anchored = true
	line.CanCollide = false
	local dist = (pointA-pointB).magnitude
	line.Size = Vector3.new(0.02,0.02,dist)
	line.CFrame = CFrame.new(pointA,pointB) * CFrame.new(0,0,-dist/2)
	line.Material = Enum.Material.Neon
	line.Transparency = 0.5
	if hit then
		line.Color = Color3.fromRGB(255,0,0)
	else
		line.Color = Color3.fromRGB(0,0,255)
	end
	table.insert(Visuals,line)
	game:GetService("Debris"):AddItem(line,1)
end

local function CheckSit()
	
end

function Anticheat.Initialize()
	Players.PlayerAdded:connect(function(player)
		player.CharacterAdded:connect(function(character)
			if player:GetRankInGroup(Settings.ExemptGroupId) < Settings.ExamptRankInt then
				TrackedCharacters[player] = {character,nil,Vector3.new(0,0,0),false,0,0,0}
			end
		end)
	end)
	RunService.Stepped:connect(function(_,deltaTime)
		local timeSinceLastStrike
		for player,trackerTable in pairs(TrackedCharacters) do
			if trackerTable[4] == false then
				local HRP
				if not trackerTable[2] then
					HRP = trackerTable[1]:FindFirstChild("HumanoidRootPart")
				end
				local humanoid = trackerTable[1]:FindFirstChildOfClass("Humanoid")
				if HRP and humanoid then
					local preventUpdate = false
					do -- teleportation patch
						if trackerTable[3] == Vector3.new(0,0,0) then
							trackerTable[3] = HRP.CFrame.p
						end
						local dist = (trackerTable[3]-HRP.CFrame.p).magnitude
						--print(dist)
						local velocity = HRP.Velocity.magnitude
						if dist > (velocity+5) and humanoid.SeatPart == nil and game:GetService("CollectionService"):HasTag(HRP,"TeleportBypass") == false then
							HRP.CFrame = CFrame.new(trackerTable[3])
							trackerTable[5] = trackerTable[5] + 1
							print("WATCH[TELEPORT]: "..tostring(player.Name))
							--[[coroutine.wrap(function()
								local function loopSet(owner)
									for _,part in pairs(trackerTable[1]:GetChildren()) do
										if part:IsA("BasePart") then
											part:SetNetworkOwner(owner)
										end
									end
								end
								loopSet(nil)
								wait(1)
								loopSet(player)
							end)()]]
							preventUpdate = true
						end
					end
					end
					do -- patches noclip
						local pA = HRP.Position
						local pB = trackerTable[3]
						local ray = Ray.new(pB,pA-pB)
						--print(ray.Direction)
						local part,_,normal = game.Workspace:FindPartOnRay(ray,trackerTable[1],true,true)
						--VisualizeHitDetection(pA,pB,part)
						if part then
							if part.CanCollide == true and part:IsGrounded() and humanoid.SeatPart == nil then
								print("WATCH[NOCLIP]: "..tostring(player.Name))
								HRP.CFrame = CFrame.new(trackerTable[3]) + (normal*3)
								preventUpdate = true
							end
						end
					end
					do -- walkspeed
					end
					if trackerTable[5] >= 5 then -- if player is detected using an exploit 5 times in under 60 seconds flag anticheat
						trackerTable[5] = 0
						--player:LoadCharacter()
						warn("POTENTIAL EXPLOITER[STRIKE LIMIT]: "..tostring(player.Name))
					elseif trackerTable[5] > 0 then
						trackerTable[6] = trackerTable[6] + deltaTime
					end
					if trackerTable[6] >= 60 then -- 60 second timer
						trackerTable[6] = 0
						trackerTable[5] = 0
					end
					if preventUpdate ~= true then
						trackerTable[3] = HRP.CFrame.p
					end
				else
					local head = trackerTable[1]:FindFirstChild("Head")
					if head then
						trackerTable[1]:BreakJoints()
					end
				end
			end
		end
	end)
end

function Anticheat.ToggleIgnore(player,toggle)
	if player then
		local trackerTable = TrackedCharacters[player]
		if trackerTable then
			if toggle == true then
				trackerTable[3] = Vector3.new(0,0,0)
			end
			trackerTable[4] = toggle
		end
	end
end

return Anticheat
