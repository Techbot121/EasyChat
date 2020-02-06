local CHATBOX = {
	Init = function(self)
		local frame = self

		self:ShowCloseButton(true)
		self:SetDraggable(true)
		self:SetSizable(true)
		self:SetDeleteOnClose(false)
		self:SetTitle("")

		self.btnClose:Hide()
		self.btnMaxim:Hide()
		self.btnMinim:Hide()

		self.BtnClose = self:Add("DButton")
		self.BtnMaxim = self:Add("DButton")
		self.Tabs = self:Add("DPropertySheet")
		self.Scroller = self.Tabs.tabScroller
		self.OldTab = NULL

		self.BtnClose:SetSize(45, 18)
		self.BtnClose:SetZPos(10)
		self.BtnClose:SetFont("DermaDefaultBold")
		self.BtnClose:SetText("X")

		self.BtnMaxim:SetSize(35, 23)
		self.BtnMaxim:SetZPos(10)
		self.BtnMaxim:SetFont("DermaLarge")
		self.BtnMaxim:SetText("▭")
		self.BtnMaxim.IsFullScreen = false
		self.BtnMaxim.DoClick = function(self)
			if not self.IsFullScreen then
				local a, b, c, d = frame:GetBounds()
				self.Before = {
					x = a,
					y = b,
					w = c,
					h = d
				}
				frame:SetSize(ScrW(), ScrH())
				frame:SetPos(0, 0)
				self.IsFullScreen = true
			else
				frame:SetPos(self.Before.x, self.Before.y)
				frame:SetSize(self.Before.w, self.Before.h)
				self.IsFullScreen = false
			end
		end

		self.Tabs:SetPos(6, 6)
		self.Tabs.old_performlayout = self.Tabs.PerformLayout
		self.Tabs.PerformLayout = function(self)
			self.old_performlayout(self)
			frame.Scroller:SetTall(22)
		end

		self.Scroller.m_iOverlap = -2
		self.Scroller:SetDragParent(self)
		self.Scroller.OnMousePressed = function(self)
			if self:IsHovered() then
				self.Dragging = { gui.MouseX() - frame.x, gui.MouseY() - frame.y }
				self:MouseCapture(true)
			end
		end

		self.Scroller.OnMouseReleased = function(self)
			self.Dragging = nil
			self:MouseCapture(false)
		end

		self.Scroller.Think = function(self)
			local mouse_x = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
			local mouse_y = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

			if self.Dragging then
				local x = mouse_x - self.Dragging[1]
				local y = mouse_y - self.Dragging[2]

				if frame:GetScreenLock() then
					x = math.Clamp(x, 0, ScrW() - self:GetWide())
					y = math.Clamp(y, 0, ScrH() - self:GetTall())
				end

				frame:SetPos(x, y)
			end

			self:SetCursor(self:IsHovered() and "sizeall" or "arrow")
		end

		if not EasyChat.UseDermaSkin then
			self.BtnClose:SetTextColor(Color(200, 20, 20))
			self.BtnMaxim:SetTextColor(Color(125, 125, 125))

			self.Paint = function(self, w, h)
				surface.SetDrawColor(EasyChat.OutlayColor)
				surface.DrawRect(6, 0, w - 13, h - 5)
				surface.SetDrawColor(EasyChat.OutlayOutlineColor)
				surface.DrawOutlinedRect(6, 0, w - 13, h - 5)
			end

			local gray_color = Color(225, 225, 225)
			self.BtnMaxim.Paint = function(self, w, h)
				surface.SetDrawColor(gray_color)
				surface.DrawRect(0, 0, w, h)
			end

			local red_color = Color(246, 40, 40)
			self.BtnClose.Paint = function(self, w, h)
				surface.SetDrawColor(red_color)
				surface.DrawRect(0, 0, w - 1, h)
			end

			local no_color = Color(0, 0, 0, 0)
			self.Tabs.Paint = function(self, w, h)
				surface.SetDrawColor(no_color)
				surface.DrawRect(0, 0, w, h)
			end
		end
	end,
	PerformLayout = function(self, w, h)
		self.Tabs:SetSize(w - 13, h - 11)
		self.BtnMaxim:SetPos(w - self.BtnMaxim:GetWide() - 50, -7)
		self.BtnClose:SetPos(w - self.BtnClose:GetWide() - 6, -2)
	end
}

vgui.Register("ECChatBox", CHATBOX, "DFrame")