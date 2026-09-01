-- TaserClientHandler.lua
-- LocalScript in StarterPlayer > StarterCharacterScripts

local TaserClientHandler = {}
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = script.Parent
local taser = character:FindFirstChild("Taser") or workspace:FindFirstChild("Taser")

local taserState = {
	isLightOn = false,
	isActive = false,
	target = nil,
}

-- Y키: 라이트 토글
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Y then
		TaserClientHandler:ToggleLight()
	end
end)

-- U키: 줄 끊기
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.U then
		TaserClientHandler:CutTether()
	end
end)

-- 마우스 클릭: 발포
local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	TaserClientHandler:Fire(mouse.Hit.Position)
end)

-- 라이트 토글
function TaserClientHandler:ToggleLight()
	if not taser then return end
	
	taserState.isLightOn = not taserState.isLightOn
	
	local light = taser:FindFirstChild("Light")
	if not light then return end
	
	local attachment = light:FindFirstChild("Attachment")
	if attachment then
		local spotlight = attachment:FindFirstChild("SpotLight")
		if spotlight then
			spotlight.Enabled = taserState.isLightOn
		end
	end
	
	-- 라이트 이펙트 토글
	local particles = light:FindFirstChild("ParticleEmitter")
	if particles then
		particles.Enabled = taserState.isLightOn
	end
	
	print("라이트: " .. (taserState.isLightOn and "ON" or "OFF"))
end

-- 발포
function TaserClientHandler:Fire(targetPosition)
	if not taser then return end
	if taserState.isActive then return end
	
	taserState.isActive = true
	
	-- 발포 이펙트
	self:PlayFireEffect()
	
	-- 서버에 발포 알림
	local event = ReplicatedStorage:FindFirstChild("TaserFire")
	if event then
		event:FireServer(targetPosition)
	end
	
	-- 타이밍 리셋 (0.5초)
	wait(0.5)
	taserState.isActive = false
end

-- 발포 이펙트
function TaserClientHandler:PlayFireEffect()
	local barrel = taser:FindFirstChild("Barrel")
	if not barrel then return end
	
	-- 빨간 플래시
	local flash = Instance.new("Part")
	flash.Name = "MuzzleFlash"
	flash.Shape = Enum.PartType.Ball
	flash.Material = Enum.Material.Neon
	flash.Color = Color3.fromRGB(255, 100, 0)
	flash.Size = Vector3.new(1, 1, 1)
	flash.CanCollide = false
	flash.CFrame = barrel.CFrame + barrel.CFrame.LookVector * 2
	flash.Parent = workspace
	
	game:GetService("Debris"):AddItem(flash, 0.1)
	
	-- 소리 재생
	self:PlaySound("Fire")
end

-- 줄 끊기
function TaserClientHandler:CutTether()
	if not taserState.isActive then return end
	
	taserState.isActive = false
	taserState.target = nil
	
	-- 서버에 알림
	local event = ReplicatedStorage:FindFirstChild("TaserCut")
	if event then
		event:FireServer()
	end
	
	print("줄이 끊어졌습니다!")
end

-- 소리 재생
function TaserClientHandler:PlaySound(soundType)
	local soundNames = {
		Fire = "rbxassetid://258688643", -- 발포음
		Electric = "rbxassetid://224339201", -- 감전음
		Cut = "rbxassetid://138080127", -- 끊김음
	}
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundNames[soundType] or ""
	sound.Volume = 1
	sound.Parent = taser or workspace
	sound:Play()
	
	game:GetService("Debris"):AddItem(sound, 2)
end

return TaserClientHandler
