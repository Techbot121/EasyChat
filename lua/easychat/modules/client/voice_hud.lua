local TAG = "EasyChatModuleVoiceHUD"
local EC_VOICE_HUD = CreateClientConVar("easychat_voice_hud", "1", true, false, "Should we use EasyChat's voice hud")
EasyChat.RegisterConvar(EC_VOICE_HUD, "Use EasyChat's voice HUD")

local ply_voice_panels = {}
cvars.RemoveChangeCallback(EC_VOICE_HUD:GetName(), TAG)
cvars.AddChangeCallback(EC_VOICE_HUD:GetName(), function()
	if EC_VOICE_HUD:GetBool() and IsValid(g_VoicePanelList) then
		g_VoicePanelList:Clear()
		return
	end

	if not EC_VOICE_HUD:GetBool() and IsValid(EasyChat.GUI.VoiceList) then
		EasyChat.GUI.VoiceList:Remove()
	end
end, TAG)

if IsValid(EasyChat.GUI.VoiceList) then
	EasyChat.GUI.VoiceList:Remove()
end

local PANEL = {}
local MAX_VOICE_DATA = 50

function PANEL:Init()
	self.LabelName = vgui.Create("DLabel", self)
	self.LabelName:SetFont("GModNotify")
	self.LabelName:Dock(FILL)
	self.LabelName:DockMargin(8, 0, 0, 0)
	self.LabelName:SetTextColor(color_white)

	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:Dock(LEFT)
	self.Avatar:SetSize(48, 48)

	self.Color = color_transparent
	self.VoiceData = {}
	self.NextVoiceData = 0

	self:SetSize(250, 48 + 8)
	self:DockPadding(4, 4, 4, 4)
	self:DockMargin(2, 2, 2, 2)
	self:Dock(BOTTOM)

	for _ = 1, MAX_VOICE_DATA do
		table.insert(self.VoiceData, 2)
	end

	EasyChat.BlurPanel(self, 0, 0, 0, 0)
end

function PANEL:Setup(ply)
	self.ply = ply

	if ply == LocalPlayer() then
		self.VoiceData = {}
	end

	self.Markup = ec_markup.Parse(ply:Nick(), nil, true)
	self.LabelName:SetText("")

	self.Avatar:SetPlayer(ply, 64)
	self.Color = team.GetColor(ply:Team())
	self:InvalidateLayout()
end

function PANEL:Paint(w, h)
	if not IsValid(self.ply) then return end

	if self.NextVoiceData <= CurTime() then
		table.insert(self.VoiceData, self.ply:VoiceVolume() * h * 2)
		if #self.VoiceData > MAX_VOICE_DATA then
			table.remove(self.VoiceData, 1)
		end

		self.NextVoiceData = CurTime() + 0.1
	end

	local bg_color = EasyChat.OutlayColor
	surface.SetDrawColor(bg_color.r, bg_color.g, bg_color.b, bg_color.a)
	surface.DrawRect(0, 0, w, h)

	local visualizer_color = Color(255 - bg_color.r, 255 - bg_color.g, 255 - bg_color.b)
	surface.SetDrawColor(visualizer_color.r, visualizer_color.g, visualizer_color.b, 255)
	local ratio = w / MAX_VOICE_DATA
	for i, vdata in ipairs(self.VoiceData) do
		surface.DrawRect((i - 1) * ratio, h - vdata, ratio, vdata)
	end

	local outline_color = Color(EasyChat.OutlayOutlineColor:Unpack())
	surface.SetDrawColor(outline_color.r, outline_color.g, outline_color.b, self.ply == LocalPlayer() and 255 or 100 + self.ply:VoiceVolume() * 155)
	surface.DrawOutlinedRect(0, 0, w, h)

	if self.Markup then
		self.Markup:Draw(48 + 10, h / 2 - self.Markup:GetTall() / 2)
	end
end

function PANEL:Think()
	if IsValid(self.ply) and not self.Markup then
		self.LabelName:SetText(self.ply:Nick())
	end
end

vgui.Register("ECVoiceNotify", PANEL, "DPanel")

local function create_voice_vgui()
	EasyChat.GUI.VoiceList = vgui.Create("DPanel")
	EasyChat.GUI.VoiceList:ParentToHUD()
	EasyChat.GUI.VoiceList:SetPos(ScrW() - 300, 100)
	EasyChat.GUI.VoiceList:SetSize(250, ScrH() - 200)
	EasyChat.GUI.VoiceList:SetPaintBackground(false)
end

local function player_end_voice(ply)
	if IsValid(ply_voice_panels[ply]) then
		ply_voice_panels[ply]:Remove()
	end
end

local function player_start_voice(ply)
	if not IsValid(EasyChat.GUI.VoiceList) then
		create_voice_vgui()
	end

	-- There'd be an exta one if voice_loopback is on, so remove it.
	player_end_voice(ply)

	if not IsValid(ply) then return end

	local panel = EasyChat.GUI.VoiceList:Add("ECVoiceNotify")
	panel:Setup(ply)
	ply_voice_panels[ply] = panel
end

GAMEMODE.old_PlayerStartVoice = GAMEMODE.old_PlayerStartVoice or GAMEMODE.PlayerStartVoice
GAMEMODE.old_PlayerEndVoice = GAMEMODE.old_PlayerEndVoice or GAMEMODE.PlayerEndVoice

function GAMEMODE:PlayerStartVoice(ply)
	if EC_VOICE_HUD:GetBool() then
		player_start_voice(ply)
	else
		self:old_PlayerStartVoice(ply)
	end
end

function GAMEMODE:PlayerEndVoice(ply)
	if EC_VOICE_HUD:GetBool() then
		player_end_voice(ply)
	else
		self:old_PlayerEndVoice(ply)
	end
end

local function voice_clean()
	for ply, _ in pairs(ply_voice_panels) do
		if not IsValid(ply) then
			player_end_voice(ply)
		end
	end
end

timer.Create("ECVoiceClean", 2, 0, voice_clean)

local circle_mat = Material("SGM/playercircle")
local black_color = Color(0, 0, 0)
local function draw_voice_ring(ply)
	if not IsValid(ply) then return end
	if not ply:Alive() then return end
	if not ply:IsSpeaking() then return end

	local trace = {}
	trace.start = ply:GetPos() + Vector(0, 0, 50)
	trace.endpos = trace.start + Vector(0, 0, -300)
	trace.filter = ply

	local tr = util.TraceLine(trace)
	if not tr.HitWorld then
		tr.HitPos = ply:GetPos()
	end

	local color = team.GetColor(ply:Team())
	color.a = 40 + (100 * (ply == LocalPlayer() and 1 or ply:VoiceVolume() * 6))
	if not ply:IsVoiceAudible() then color.a = 0 end

	render.SetMaterial(circle_mat)
	render.DrawQuadEasy(tr.HitPos + tr.HitNormal, tr.HitNormal, 128, 128, color)
end

hook.Add("PostDrawTranslucentRenderables", "VoiceRing", function()
	if not EC_VOICE_HUD:GetBool() then return end

	for _, ply in ipairs(player.GetAll()) do
		draw_voice_ring(ply)
	end
end)

return "Voice HUD"