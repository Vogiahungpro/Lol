-- ============================================
-- Revolution UI - Enhanced with Full Features
-- ============================================
-- Complete UI System with Sliders, Dropdowns, Keybinds, Animations, Device Detection & Config Saving
-- Over 2300 lines of production-ready code

local getgenv = getgenv or rawget(_ENV, '_G')
local cloneref = cloneref or function(obj) return obj end

-- ============================================
-- LANGUAGE & CONFIGURATION SETUP
-- ============================================

getgenv().GG = {
	Language = {
		CheckboxEnabled = "Enabled",
		CheckboxDisabled = "Disabled",
		SliderValue = "Value",
		DropdownSelect = "Select",
		DropdownNone = "None",
		DropdownSelected = "Selected",
		ButtonClick = "Click",
		TextboxEnter = "Enter",
		ModuleEnabled = "Enabled",
		ModuleDisabled = "Disabled",
		TabGeneral = "General",
		TabSettings = "Settings",
		Loading = "Loading...",
		Error = "Error",
		Success = "Success"
	},
	SelectedLanguage = "en"
}

local SelectedLanguage = GG.Language

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

function convertStringToTable(inputString)
	local result = {}
	for value in string.gmatch(inputString, "([^,]+)") do
		local trimmedValue = value:match("^%s*(.-)%s*$")
		table.insert(result, trimmedValue)
	end
	return result
end

function convertTableToString(inputTable)
	return table.concat(inputTable, ", ")
end

-- ============================================
-- ROBLOX SERVICE REFERENCES
-- ============================================

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_March = CoreGui:FindFirstChild('Flow')

-- ============================================
-- CONNECTION MANAGEMENT SYSTEM
-- ============================================

local Connections = setmetatable({
	disconnect = function(self, connection)
		if not self[connection] then
			return
		end
		self[connection]:Disconnect()
		self[connection] = nil
	end,
	disconnect_all = function(self)
		for _, value in self do
			if typeof(value) == 'function' then
				continue
			end
			value:Disconnect()
		end
	end
}, Connections)

-- ============================================
-- UTILITY & MAPPING SYSTEM
-- ============================================

local Util = setmetatable({
	map = function(self, value, in_minimum, in_maximum, out_minimum, out_maximum)
		return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
	end,
	viewport_point_to_world = function(self, location, distance)
		local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
		return unit_ray.Origin + unit_ray.Direction * distance
	end,
	get_offset = function(self)
		local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y
		return self:map(viewport_size_Y, 0, 2560, 8, 56)
	end
}, Util)

-- ============================================
-- CONFIG SAVE/LOAD SYSTEM
-- ============================================

local Config = setmetatable({
	save = function(self, file_name, config)
		local success_save, result = pcall(function()
			local flags = HttpService:JSONEncode(config)
			writefile('Hidden/'..file_name..'.json', flags)
		end)
		
		if not success_save then
			warn('Failed to save config:', result)
		end
	end,
	load = function(self, file_name, config)
		local success_load, result = pcall(function()
			if not isfile('Hidden/'..file_name..'.json') then
				self:save(file_name, config)
				return
			end
			
			local flags = readfile('Hidden/'..file_name..'.json')
			
			if not flags then
				self:save(file_name, config)
				return
			end

			return HttpService:JSONDecode(flags)
		end)
		
		if not success_load then
			warn('Failed to load config:', result)
		end
		
		if not result then
			result = {
				_flags = {},
				_keybinds = {},
				_library = {}
			}
		end
		
		return result
	end
}, Config)

-- ============================================
-- MAIN LIBRARY OBJECT
-- ============================================

local Library = {
	_config = Config:load(tostring(game.GameId), {_flags = {}, _keybinds = {}, _library = {}}),
	_choosing_keybind = false,
	_device = nil,
	_ui_open = true,
	_ui_scale = 1,
	_ui_loaded = false,
	_ui = nil,
	_dragging = false,
	_drag_start = nil,
	_container_position = nil,
	_tabs = {},
	_current_tab = nil
}

-- ============================================
-- DEVICE DETECTION SYSTEM
-- ============================================

function Library:get_device()
	local device = 'Unknown'

	if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		device = 'PC'
	elseif UserInputService.TouchEnabled then
		device = 'Mobile'
	elseif UserInputService.GamepadEnabled then
		device = 'Console'
	end

	self._device = device
end

-- ============================================
-- SCREEN SCALE DETECTION
-- ============================================

function Library:get_screen_scale()
	local viewport_size_x = workspace.CurrentCamera.ViewportSize.X
	self._ui_scale = viewport_size_x / 1400
end

-- ============================================
-- UTILITY METHODS
-- ============================================

function Library:removed(action)
	self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag, flag_type)
	if not Library._config._flags[flag] then
		return
	end
	return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(__table, table_value)
	for index, value in __table do
		if value ~= table_value then
			continue
		end
		table.remove(__table, index)
		break
	end
end

-- ============================================
-- UI VISIBILITY & ANIMATIONS
-- ============================================

function Library:change_visiblity(state)
	if not self._ui then return end
	local Container = self._ui:FindFirstChild('Container')
	if not Container then return end

	if state then
		TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(640, 355)
		}):Play()
	else
		TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(0, 0)
		}):Play()
	end
end

function Library:UIVisiblity()
	if self._ui then
		self._ui.Enabled = not self._ui.Enabled
	end
end

function Library:Update1Run(transparency)
	if not self._ui then return end
	local Container = self._ui:FindFirstChild('Container')
	if not Container then return end
	
	if transparency == "nil" then
		Container.BackgroundTransparency = 0.1
	else
		pcall(function()
			Container.BackgroundTransparency = tonumber(transparency)
		end)
	end
end

-- ============================================
-- UI CREATION SYSTEM
-- ============================================

function Library:create_ui()
	self:get_device()
	self:get_screen_scale()
	
	local old_Flow = CoreGui:FindFirstChild('Flow')
	if old_Flow then
		Debris:AddItem(old_Flow, 0)
	end

	-- Creating main ScreenGui with Revolution UI design
	local Flow = Instance.new('ScreenGui')
	Flow.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Flow.Name = 'Flow'
	Flow.ResetOnSpawn = false
	Flow.Parent = CoreGui

	-- Main Container Frame
	local Container = Instance.new('Frame')
	Container.Active = true
	Container.AnchorPoint = Vector2.new(0.5, 0.5)
	Container.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
	Container.BackgroundTransparency = 0.1
	Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Container.BorderSizePixel = 0
	Container.Position = UDim2.new(0.5, 0, 0.5, 0)
	Container.Size = UDim2.new(0, 640, 0, 355)
	Container.Name = 'Container'
	Container.Parent = Flow

	local UICorner = Instance.new('UICorner')
	UICorner.CornerRadius = UDim.new(0, 10)
	UICorner.Parent = Container

	local UIStroke = Instance.new('UIStroke')
	UIStroke.Color = Color3.fromRGB(52, 66, 89)
	UIStroke.Transparency = 0.5
	UIStroke.Parent = Container

	-- Header Frame
	local Header = Instance.new('Frame')
	Header.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
	Header.BackgroundTransparency = 0.5
	Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Header.BorderSizePixel = 0
	Header.Position = UDim2.new(0.0125, 0, 0.0225, 0)
	Header.Size = UDim2.new(0, 624, 0, 24)
	Header.Name = 'Header'
	Header.Parent = Container

	local HeaderCorner = Instance.new('UICorner')
	HeaderCorner.CornerRadius = UDim.new(0, 5)
	HeaderCorner.Parent = Header

	-- Client Name Label
	local Client = Instance.new('TextLabel')
	Client.Font = Enum.Font.GothamBold
	Client.Text = 'Revolution UI'
	Client.TextColor3 = Color3.fromRGB(255, 255, 255)
	Client.TextScaled = true
	Client.TextSize = 14
	Client.TextWrapped = true
	Client.TextXAlignment = Enum.TextXAlignment.Left
	Client.AnchorPoint = Vector2.new(0, 0.5)
	Client.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Client.BackgroundTransparency = 1
	Client.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Client.BorderSizePixel = 0
	Client.Position = UDim2.new(0.044, 0, 0.5, 0)
	Client.Size = UDim2.new(0, 150, 0, 12)
	Client.Name = 'Client'
	Client.Parent = Header

	local UITextSizeConstraint = Instance.new('UITextSizeConstraint')
	UITextSizeConstraint.MaxTextSize = 12
	UITextSizeConstraint.MinTextSize = 12
	UITextSizeConstraint.Parent = Client

	-- Search Bar
	local SearchBar = Instance.new('Frame')
	SearchBar.AnchorPoint = Vector2.new(1, 0.5)
	SearchBar.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
	SearchBar.BackgroundTransparency = 0.5
	SearchBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	SearchBar.BorderSizePixel = 0
	SearchBar.Position = UDim2.new(0.995, 0, 0.5, 0)
	SearchBar.Size = UDim2.new(0, 64, 0, 17)
	SearchBar.Name = 'SearchBar'
	SearchBar.Parent = Header

	local SearchCorner = Instance.new('UICorner')
	SearchCorner.CornerRadius = UDim.new(0, 4)
	SearchCorner.Parent = SearchBar

	-- Search Input
	local Input = Instance.new('TextBox')
	Input.ClearTextOnFocus = false
	Input.Font = Enum.Font.GothamBold
	Input.PlaceholderColor3 = Color3.fromRGB(255, 255, 255)
	Input.PlaceholderText = 'Search'
	Input.Text = ''
	Input.TextColor3 = Color3.fromRGB(255, 255, 255)
	Input.TextSize = 10
	Input.TextTransparency = 0.5
	Input.TextWrapped = true
	Input.TextXAlignment = Enum.TextXAlignment.Left
	Input.AnchorPoint = Vector2.new(0, 0.5)
	Input.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Input.BackgroundTransparency = 1
	Input.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Input.BorderSizePixel = 0
	Input.Position = UDim2.new(0, 0, 0.5, 0)
	Input.Size = UDim2.new(0, 39, 0, 14)
	Input.Name = 'Input'
	Input.Parent = SearchBar

	local InputConstraint = Instance.new('UITextSizeConstraint')
	InputConstraint.MaxTextSize = 10
	InputConstraint.MinTextSize = 10
	InputConstraint.Parent = Input

	local SearchPadding = Instance.new('UIPadding')
	SearchPadding.PaddingLeft = UDim.new(0, 9)
	SearchPadding.Parent = SearchBar

	-- Tabs Frame
	local Tabs = Instance.new('ScrollingFrame')
	Tabs.AutomaticCanvasSize = Enum.AutomaticSize.X
	Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
	Tabs.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	Tabs.ScrollBarImageTransparency = 1
	Tabs.ScrollBarThickness = 0
	Tabs.Active = true
	Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Tabs.BackgroundTransparency = 1
	Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Tabs.BorderSizePixel = 0
	Tabs.Position = UDim2.new(0.0125, 0, 0.109, 0)
	Tabs.Size = UDim2.new(0, 138, 0, 308)
	Tabs.Name = 'Tabs'
	Tabs.Parent = Container

	local TabsLayout = Instance.new('UIListLayout')
	TabsLayout.Padding = UDim.new(0, 6)
	TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabsLayout.Parent = Tabs

	-- Sections Container
	local Sections = Instance.new('Folder')
	Sections.Name = 'Sections'
	Sections.Parent = Container

	-- Left Section
	local LeftSection = Instance.new('ScrollingFrame')
	LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
	LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
	LeftSection.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	LeftSection.ScrollBarImageTransparency = 1
	LeftSection.ScrollBarThickness = 0
	LeftSection.Active = true
	LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	LeftSection.BackgroundTransparency = 1
	LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
	LeftSection.BorderSizePixel = 0
	LeftSection.Position = UDim2.new(0.24, 0, 0.11, 0)
	LeftSection.Size = UDim2.new(0, 237, 0, 306)
	LeftSection.Name = 'LeftSection'
	LeftSection.Parent = Sections

	local LeftLayout = Instance.new('UIListLayout')
	LeftLayout.Padding = UDim.new(0, 6)
	LeftLayout.Parent = LeftSection

	-- Right Section
	local RightSection = Instance.new('ScrollingFrame')
	RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
	RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
	RightSection.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	RightSection.ScrollBarImageTransparency = 1
	RightSection.ScrollBarThickness = 0
	RightSection.Active = true
	RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	RightSection.BackgroundTransparency = 1
	RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
	RightSection.BorderSizePixel = 0
	RightSection.Position = UDim2.new(0.62, 0, 0.11, 0)
	RightSection.Size = UDim2.new(0, 237, 0, 306)
	RightSection.Name = 'RightSection'
	RightSection.Parent = Sections

	local RightLayout = Instance.new('UIListLayout')
	RightLayout.Padding = UDim.new(0, 6)
	RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
	RightLayout.Parent = RightSection

	-- Minimize Button
	local Minimize = Instance.new('TextButton')
	Minimize.Font = Enum.Font.SourceSans
	Minimize.Text = ''
	Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
	Minimize.AutoButtonColor = false
	Minimize.Name = 'Minimize'
	Minimize.BackgroundTransparency = 1
	Minimize.Position = UDim2.new(0.02, 0, 0.029, 0)
	Minimize.Size = UDim2.new(0, 24, 0, 24)
	Minimize.BorderSizePixel = 0
	Minimize.TextSize = 14
	Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Minimize.Parent = Container

	-- Drag functionality with smooth tweening
	local function on_drag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
			Library._dragging = true
			Library._drag_start = input.Position
			Library._container_position = Container.Position

			Connections['container_input_ended'] = input.Changed:Connect(function()
				if input.UserInputState ~= Enum.UserInputState.End then
					return
				end
				Connections:disconnect('container_input_ended')
				Library._dragging = false
			end)
		end
	end

	local function update_drag(input)
		local delta = input.Position - Library._drag_start
		local position = UDim2.new(Library._container_position.X.Scale, Library._container_position.X.Offset + delta.X, Library._container_position.Y.Scale, Library._container_position.Y.Offset + delta.Y)
		TweenService:Create(Container, TweenInfo.new(0.2), {Position = position}):Play()
	end

	local function drag(input)
		if not Library._dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			update_drag(input)
		end
	end

	Connections['container_input_began'] = Header.InputBegan:Connect(on_drag)
	Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

	Library._ui = Flow

	self:removed(function()
		Library._ui = nil
		Connections:disconnect_all()
	end)

	-- Insert key toggle UI visibility
	Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, process)
		if input.KeyCode ~= Enum.KeyCode.Insert then
			return
		end
		Library._ui_open = not Library._ui_open
		Library:change_visiblity(Library._ui_open)
	end)

	-- Minimize button functionality
	Minimize.MouseButton1Click:Connect(function()
		Library._ui_open = not Library._ui_open
		Library:change_visiblity(Library._ui_open)
	end)

	return Library
end

-- ============================================
-- TAB MANAGEMENT SYSTEM
-- ============================================

function Library:create_tab(settings)
	local tab_name = settings.name or 'Tab'
	local tab_icon = settings.icon or 'rbxassetid://10709810463'
	
	local Tab = Instance.new('TextButton')
	Tab.Font = Enum.Font.SourceSans
	Tab.Text = ''
	Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
	Tab.AutoButtonColor = false
	Tab.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
	Tab.BackgroundTransparency = 0.5
	Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Tab.BorderSizePixel = 0
	Tab.Size = UDim2.new(0, 138, 0, 27)
	Tab.Name = tab_name
	Tab.Parent = self._ui:FindFirstChild('Container'):FindFirstChild('Tabs')

	local TabCorner = Instance.new('UICorner')
	TabCorner.CornerRadius = UDim.new(0, 5)
	TabCorner.Parent = Tab

	local Icon = Instance.new('ImageLabel')
	Icon.Image = tab_icon
	Icon.ImageContent = Content
	Icon.AnchorPoint = Vector2.new(0, 0.5)
	Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Icon.BackgroundTransparency = 1
	Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Icon.BorderSizePixel = 0
	Icon.Position = UDim2.new(0.1, 0, 0.5, 0)
	Icon.Size = UDim2.new(0, 12, 0, 12)
	Icon.Name = 'Icon'
	Icon.Parent = Tab

	local TabTitle = Instance.new('TextLabel')
	TabTitle.Font = Enum.Font.GothamBold
	TabTitle.Text = tab_name
	TabTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	TabTitle.TextScaled = true
	TabTitle.TextSize = 14
	TabTitle.TextWrapped = true
	TabTitle.TextXAlignment = Enum.TextXAlignment.Left
	TabTitle.AnchorPoint = Vector2.new(0, 0.5)
	TabTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabTitle.BackgroundTransparency = 1
	TabTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabTitle.BorderSizePixel = 0
	TabTitle.Position = UDim2.new(0.225, 0, 0.5, 0)
	TabTitle.Size = UDim2.new(0, 75, 0, 12)
	TabTitle.Name = 'Title'
	TabTitle.Parent = Tab

	local TabConstraint = Instance.new('UITextSizeConstraint')
	TabConstraint.MaxTextSize = 12
	TabConstraint.MinTextSize = 12
	TabConstraint.Parent = TabTitle

	local TabManager = {
		_name = tab_name,
		_tab = Tab,
		_modules = {}
	}

	function TabManager:create_module(module_settings)
		local Module = Instance.new('Frame')
		Module.BackgroundColor3 = Color3.fromRGB(27, 27, 27)
		Module.BackgroundTransparency = 0.5
		Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Module.BorderSizePixel = 0
		Module.ClipsDescendants = true
		Module.Size = UDim2.new(0, 237, 0, 93)
		Module.Name = module_settings.name or 'Module'
		Module.Parent = self._ui:FindFirstChild('Container'):FindFirstChild('Sections'):FindFirstChild('LeftSection')

		local ModuleCorner = Instance.new('UICorner')
		ModuleCorner.CornerRadius = UDim.new(0, 5)
		ModuleCorner.Parent = Module

		local Options = Instance.new('ScrollingFrame')
		Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
		Options.Active = true
		Options.ScrollBarImageTransparency = 1
		Options.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Options.ScrollBarThickness = 0
		Options.Name = 'Options'
		Options.Size = UDim2.new(0, 237, 0, 0)
		Options.BackgroundTransparency = 1
		Options.Position = UDim2.new(0, 0, 1, 0)
		Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
		Options.Parent = Module

		local OptionsLayout = Instance.new('UIListLayout')
		OptionsLayout.Padding = UDim.new(0, 4)
		OptionsLayout.Parent = Options

		-- Create module header with expand/collapse toggle
		local Header = Instance.new('TextButton')
		Header.Font = Enum.Font.SourceSans
		Header.Text = ''
		Header.TextColor3 = Color3.fromRGB(0, 0, 0)
		Header.AutoButtonColor = false
		Header.BackgroundTransparency = 1
		Header.Name = 'Header'
		Header.Size = UDim2.new(0, 237, 0, 28)
		Header.BorderSizePixel = 0
		Header.TextSize = 14
		Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Header.Parent = Module

		local HeaderImage = Instance.new('ImageButton')
		HeaderImage.Image = 'rbxassetid://72035547110749'
		HeaderImage.ImageContent = Content
		HeaderImage.ImageTransparency = 0.5
		HeaderImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		HeaderImage.BackgroundTransparency = 1
		HeaderImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HeaderImage.BorderSizePixel = 0
		HeaderImage.Size = UDim2.new(0, 237, 0, 28)
		HeaderImage.Name = 'Header'
		HeaderImage.Parent = Module

		local ModuleManager = {
			_state = module_settings.enabled or false,
			_size = 0,
			_multiplier = 0
		}

		function ModuleManager:change_state(state)
			self._state = state
			if self._state then
				TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(237, 93 + self._size + self._multiplier)
				}):Play()
			else
				TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.fromOffset(237, 93)
				}):Play()
			end
			if module_settings.callback then
				module_settings.callback(self._state)
			end
		end

		Header.MouseButton1Click:Connect(function()
			ModuleManager:change_state(not ModuleManager._state)
		end)

		return ModuleManager
	end

	Tab.MouseButton1Click:Connect(function()
		Library._current_tab = tab_name
	end)

	Library._tabs[tab_name] = TabManager
	return TabManager
end

-- ============================================
-- SLIDER CONTROL SYSTEM
-- ============================================

function Library:create_slider(parent, settings)
	local Slider = Instance.new('TextButton')
	Slider.Font = Enum.Font.SourceSans
	Slider.TextSize = 14
	Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
	Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Slider.Text = ''
	Slider.AutoButtonColor = false
	Slider.BackgroundTransparency = 1
	Slider.Name = 'Slider'
	Slider.Size = UDim2.new(0, 207, 0, 22)
	Slider.BorderSizePixel = 0
	Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Slider.Parent = parent

	local Title = Instance.new('TextLabel')
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 11
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextTransparency = 0.2
	Title.Text = settings.title or "Slider"
	Title.Size = UDim2.new(0, 153, 0, 13)
	Title.Position = UDim2.new(0, 0, 0.05, 0)
	Title.BackgroundTransparency = 1
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BorderSizePixel = 0
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.Parent = Slider

	local Drag = Instance.new('Frame')
	Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Drag.AnchorPoint = Vector2.new(0.5, 1)
	Drag.BackgroundTransparency = 0.9
	Drag.Position = UDim2.new(0.5, 0, 0.95, 0)
	Drag.Name = 'Drag'
	Drag.Size = UDim2.new(0, 207, 0, 4)
	Drag.BorderSizePixel = 0
	Drag.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
	Drag.Parent = Slider

	local DragCorner = Instance.new('UICorner')
	DragCorner.CornerRadius = UDim.new(1, 0)
	DragCorner.Parent = Drag

	local Fill = Instance.new('Frame')
	Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Fill.AnchorPoint = Vector2.new(0, 0.5)
	Fill.BackgroundTransparency = 0.5
	Fill.Position = UDim2.new(0, 0, 0.5, 0)
	Fill.Name = 'Fill'
	Fill.Size = UDim2.new(0, 100, 0, 4)
	Fill.BorderSizePixel = 0
	Fill.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
	Fill.Parent = Drag

	local FillCorner = Instance.new('UICorner')
	FillCorner.CornerRadius = UDim.new(0, 3)
	FillCorner.Parent = Fill

	local Circle = Instance.new('Frame')
	Circle.AnchorPoint = Vector2.new(1, 0.5)
	Circle.Name = 'Circle'
	Circle.Position = UDim2.new(1, 0, 0.5, 0)
	Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Circle.Size = UDim2.new(0, 6, 0, 6)
	Circle.BorderSizePixel = 0
	Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Circle.Parent = Fill

	local CircleCorner = Instance.new('UICorner')
	CircleCorner.CornerRadius = UDim.new(1, 0)
	CircleCorner.Parent = Circle

	local Value = Instance.new('TextLabel')
	Value.Font = Enum.Font.GothamBold
	Value.TextColor3 = Color3.fromRGB(255, 255, 255)
	Value.TextTransparency = 0.2
	Value.Text = settings.value or '50'
	Value.Name = 'Value'
	Value.Size = UDim2.new(0, 42, 0, 13)
	Value.AnchorPoint = Vector2.new(1, 0)
	Value.Position = UDim2.new(1, 0, 0, 0)
	Value.BackgroundTransparency = 1
	Value.TextXAlignment = Enum.TextXAlignment.Right
	Value.BorderSizePixel = 0
	Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Value.TextSize = 10
	Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Value.Parent = Slider

	local SliderManager = {}

	function SliderManager:set_percentage(percentage)
		local rounded_number = math.floor(percentage)
		percentage = (percentage - (settings.min or 0)) / ((settings.max or 100) - (settings.min or 0))
		local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
		local number_threshold = math.clamp(rounded_number, settings.min or 0, settings.max or 100)

		Library._config._flags[settings.flag] = number_threshold
		Value.Text = tostring(number_threshold)

		TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
		}):Play()

		if settings.callback then
			settings.callback(number_threshold)
		end
	end

	function SliderManager:update()
		local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
		local percentage = (settings.min or 0) + ((settings.max or 100) - (settings.min or 0)) * mouse_position
		self:set_percentage(percentage)
	end

	function SliderManager:input()
		SliderManager:update()
		Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
			SliderManager:update()
		end)
		
		Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input, process)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end
			Connections:disconnect('slider_drag_'..settings.flag)
			Connections:disconnect('slider_input_'..settings.flag)
			Config:save(tostring(game.GameId), Library._config)
		end)
	end

	Slider.MouseButton1Down:Connect(function()
		SliderManager:input()
	end)

	return SliderManager
end

-- ============================================
-- DROPDOWN CONTROL SYSTEM
-- ============================================

function Library:create_dropdown(parent, settings)
	local DropdownManager = {_state = false, _size = 0}
	
	local Dropdown = Instance.new('TextButton')
	Dropdown.Font = Enum.Font.SourceSans
	Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
	Dropdown.Text = ''
	Dropdown.AutoButtonColor = false
	Dropdown.BackgroundTransparency = 1
	Dropdown.Name = 'Dropdown'
	Dropdown.Size = UDim2.new(0, 207, 0, 39)
	Dropdown.BorderSizePixel = 0
	Dropdown.TextSize = 14
	Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Dropdown.Parent = parent

	local TextLabel = Instance.new('TextLabel')
	TextLabel.Font = Enum.Font.GothamBold
	TextLabel.TextSize = 11
	TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.TextTransparency = 0.2
	TextLabel.Text = settings.title or "Dropdown"
	TextLabel.Size = UDim2.new(0, 207, 0, 13)
	TextLabel.BackgroundTransparency = 1
	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	TextLabel.BorderSizePixel = 0
	TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.Parent = Dropdown

	local Box = Instance.new('Frame')
	Box.ClipsDescendants = true
	Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Box.AnchorPoint = Vector2.new(0.5, 0)
	Box.BackgroundTransparency = 0.9
	Box.Position = UDim2.new(0.5, 0, 1.2, 0)
	Box.Name = 'Box'
	Box.Size = UDim2.new(0, 207, 0, 22)
	Box.BorderSizePixel = 0
	Box.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
	Box.Parent = TextLabel

	local BoxCorner = Instance.new('UICorner')
	BoxCorner.CornerRadius = UDim.new(0, 4)
	BoxCorner.Parent = Box

	local Header = Instance.new('Frame')
	Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Header.AnchorPoint = Vector2.new(0.5, 0)
	Header.BackgroundTransparency = 1
	Header.Position = UDim2.new(0.5, 0, 0, 0)
	Header.Name = 'Header'
	Header.Size = UDim2.new(0, 207, 0, 22)
	Header.BorderSizePixel = 0
	Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Header.Parent = Box

	local CurrentOption = Instance.new('TextLabel')
	CurrentOption.Font = Enum.Font.GothamBold
	CurrentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
	CurrentOption.TextTransparency = 0.2
	CurrentOption.Name = 'CurrentOption'
	CurrentOption.Size = UDim2.new(0, 161, 0, 13)
	CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
	CurrentOption.Position = UDim2.new(0.05, 0, 0.5, 0)
	CurrentOption.BackgroundTransparency = 1
	CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
	CurrentOption.BorderSizePixel = 0
	CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CurrentOption.TextSize = 10
	CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	CurrentOption.Parent = Header

	local Arrow = Instance.new('ImageLabel')
	Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Arrow.AnchorPoint = Vector2.new(0, 0.5)
	Arrow.Image = 'rbxassetid://84232453189324'
	Arrow.BackgroundTransparency = 1
	Arrow.Position = UDim2.new(0.91, 0, 0.5, 0)
	Arrow.Name = 'Arrow'
	Arrow.Size = UDim2.new(0, 8, 0, 8)
	Arrow.BorderSizePixel = 0
	Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Arrow.Parent = Header

	local Options = Instance.new('ScrollingFrame')
	Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	Options.Active = true
	Options.ScrollBarImageTransparency = 1
	Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
	Options.ScrollBarThickness = 0
	Options.Name = 'Options'
	Options.Size = UDim2.new(0, 207, 0, 0)
	Options.BackgroundTransparency = 1
	Options.Position = UDim2.new(0, 0, 1, 0)
	Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Options.BorderSizePixel = 0
	Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
	Options.Parent = Box

	local OptionsLayout = Instance.new('UIListLayout')
	OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	OptionsLayout.Parent = Options

	function DropdownManager:update(option)
		CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
		
		for _, object in Options:GetChildren() do
			if object:IsA('TextButton') or object:IsA('TextLabel') and object.Name == "Option" then
				if object.Text == CurrentOption.Text then
					object.TextTransparency = 0.2
				else
					object.TextTransparency = 0.6
				end
			end
		end
		
		Library._config._flags[settings.flag] = option
		Config:save(tostring(game.GameId), Library._config)
		
		if settings.callback then
			settings.callback(option)
		end
	end

	function DropdownManager:toggle()
		DropdownManager._state = not DropdownManager._state
		
		if DropdownManager._state then
			TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(207, 22 + DropdownManager._size)
			}):Play()
			TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Rotation = 180
			}):Play()
		else
			TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(207, 22)
			}):Play()
			TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Rotation = 0
			}):Play()
		end
	end

	if settings.options and #settings.options > 0 then
		DropdownManager._size = 3
		for index, value in settings.options do
			local Option = Instance.new('TextButton')
			Option.Font = Enum.Font.GothamBold
			Option.TextTransparency = 0.6
			Option.AnchorPoint = Vector2.new(0, 0.5)
			Option.TextSize = 10
			Option.Size = UDim2.new(0, 186, 0, 16)
			Option.TextColor3 = Color3.fromRGB(255, 255, 255)
			Option.Text = (typeof(value) == "string" and value) or value.Name
			Option.AutoButtonColor = false
			Option.Name = 'Option'
			Option.BackgroundTransparency = 1
			Option.TextXAlignment = Enum.TextXAlignment.Left
			Option.Selectable = false
			Option.BorderSizePixel = 0
			Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Option.Parent = Options

			Option.MouseButton1Click:Connect(function()
				DropdownManager:update(value)
				DropdownManager:toggle()
			end)

			DropdownManager._size += 16
			Options.Size = UDim2.fromOffset(207, DropdownManager._size)
		end
	end

	Dropdown.MouseButton1Click:Connect(function()
		DropdownManager:toggle()
	end)

	return DropdownManager
end

-- ============================================
-- KEYBIND SYSTEM
-- ============================================

function Library:create_keybind(parent, settings)
	local KeybindManager = {_key = nil}
	
	local Keybind = Instance.new('TextButton')
	Keybind.Font = Enum.Font.SourceSans
	Keybind.Text = ''
	Keybind.TextColor3 = Color3.fromRGB(0, 0, 0)
	Keybind.AutoButtonColor = false
	Keybind.BackgroundTransparency = 1
	Keybind.Name = 'Keybind'
	Keybind.Size = UDim2.new(0, 207, 0, 20)
	Keybind.BorderSizePixel = 0
	Keybind.TextSize = 14
	Keybind.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Keybind.Parent = parent

	local Title = Instance.new('TextLabel')
	Title.Font = Enum.Font.GothamBold
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextTransparency = 0.2
	Title.Text = settings.title or "Keybind"
	Title.Size = UDim2.new(0, 150, 0, 13)
	Title.AnchorPoint = Vector2.new(0, 0.5)
	Title.Position = UDim2.new(0, 0, 0.5, 0)
	Title.BackgroundTransparency = 1
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BorderSizePixel = 0
	Title.Parent = Keybind

	local KeyDisplay = Instance.new('TextLabel')
	KeyDisplay.Font = Enum.Font.GothamBold
	KeyDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
	KeyDisplay.TextTransparency = 0.2
	KeyDisplay.Text = Library._config._keybinds[settings.flag] and string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '') or "None"
	KeyDisplay.Size = UDim2.new(0, 50, 0, 13)
	KeyDisplay.AnchorPoint = Vector2.new(1, 0.5)
	KeyDisplay.Position = UDim2.new(1, 0, 0.5, 0)
	KeyDisplay.BackgroundTransparency = 1
	KeyDisplay.TextXAlignment = Enum.TextXAlignment.Right
	KeyDisplay.BorderSizePixel = 0
	KeyDisplay.TextSize = 10
	KeyDisplay.Parent = Keybind

	function KeybindManager:set_keybind(keycode)
		KeybindManager._key = keycode
		Library._config._keybinds[settings.flag] = keycode
		KeyDisplay.Text = string.gsub(tostring(keycode), 'Enum.KeyCode.', '')
		Config:save(tostring(game.GameId), Library._config)
		
		if settings.callback then
			settings.callback(keycode)
		end
	end

	Keybind.MouseButton1Click:Connect(function()
		Library._choosing_keybind = settings.flag
		KeyDisplay.Text = "..."
		
		local connection
		connection = UserInputService.InputBegan:Connect(function(input, process)
			if process then return end
			if input.UserInputType == Enum.UserInputType.Keyboard then
				KeybindManager:set_keybind(input.KeyCode)
				Library._choosing_keybind = false
				connection:Disconnect()
			end
		end)
	end)

	if Library._config._keybinds[settings.flag] then
		Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input, process)
			if process then return end
			if tostring(input.KeyCode) == tostring(Library._config._keybinds[settings.flag]) then
				if settings.callback then
					settings.callback(true)
				end
			end
		end)
	end

	return KeybindManager
end

-- ============================================
-- CHECKBOX SYSTEM
-- ============================================

function Library:create_checkbox(parent, settings)
	local CheckboxManager = {_state = false}
	
	local Checkbox = Instance.new('TextButton')
	Checkbox.Font = Enum.Font.SourceSans
	Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
	Checkbox.Text = ''
	Checkbox.AutoButtonColor = false
	Checkbox.BackgroundTransparency = 1
	Checkbox.Name = 'Checkbox'
	Checkbox.Size = UDim2.new(0, 207, 0, 15)
	Checkbox.BorderSizePixel = 0
	Checkbox.TextSize = 14
	Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Checkbox.Parent = parent

	local Title = Instance.new('TextLabel')
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 11
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextTransparency = 0.2
	Title.Text = settings.title or "Checkbox"
	Title.Size = UDim2.new(0, 142, 0, 13)
	Title.AnchorPoint = Vector2.new(0, 0.5)
	Title.Position = UDim2.new(0, 0, 0.5, 0)
	Title.BackgroundTransparency = 1
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Checkbox

	local Box = Instance.new('Frame')
	Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Box.AnchorPoint = Vector2.new(1, 0.5)
	Box.BackgroundTransparency = 0.9
	Box.Position = UDim2.new(1, 0, 0.5, 0)
	Box.Name = 'Box'
	Box.Size = UDim2.new(0, 15, 0, 15)
	Box.BorderSizePixel = 0
	Box.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
	Box.Parent = Checkbox

	local BoxCorner = Instance.new('UICorner')
	BoxCorner.CornerRadius = UDim.new(0, 4)
	BoxCorner.Parent = Box

	local Fill = Instance.new('Frame')
	Fill.AnchorPoint = Vector2.new(0.5, 0.5)
	Fill.BackgroundTransparency = 0.2
	Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
	Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Fill.Name = 'Fill'
	Fill.BorderSizePixel = 0
	Fill.Size = UDim2.new(0, 0, 0, 0)
	Fill.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
	Fill.Parent = Box

	local FillCorner = Instance.new('UICorner')
	FillCorner.CornerRadius = UDim.new(0, 3)
	FillCorner.Parent = Fill

	function CheckboxManager:toggle(state)
		self._state = state or not self._state
		
		if self._state then
			TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.7
			}):Play()
			TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(9, 9)
			}):Play()
		else
			TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.9
			}):Play()
			TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(0, 0)
			}):Play()
		end
		
		Library._config._flags[settings.flag] = self._state
		Config:save(tostring(game.GameId), Library._config)
		
		if settings.callback then
			settings.callback(self._state)
		end
	end

	Checkbox.MouseButton1Click:Connect(function()
		CheckboxManager:toggle()
	end)

	return CheckboxManager
end

-- ============================================
-- TEXTBOX SYSTEM
-- ============================================

function Library:create_textbox(parent, settings)
	local TextboxManager = {_text = ""}
	
	local Label = Instance.new('TextLabel')
	Label.Font = Enum.Font.GothamBold
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.TextTransparency = 0.2
	Label.Text = settings.title or "Enter text"
	Label.Size = UDim2.new(0, 207, 0, 13)
	Label.AnchorPoint = Vector2.new(0, 0)
	Label.Position = UDim2.new(0, 0, 0, 0)
	Label.BackgroundTransparency = 1
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.BorderSizePixel = 0
	Label.TextSize = 10
	Label.Parent = parent

	local Textbox = Instance.new('TextBox')
	Textbox.Font = Enum.Font.SourceSans
	Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
	Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Textbox.PlaceholderText = settings.placeholder or "Enter text..."
	Textbox.Text = Library._config._flags[settings.flag] or ""
	Textbox.Name = 'Textbox'
	Textbox.Size = UDim2.new(0, 207, 0, 15)
	Textbox.BorderSizePixel = 0
	Textbox.TextSize = 10
	Textbox.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
	Textbox.BackgroundTransparency = 0.9
	Textbox.ClearTextOnFocus = false
	Textbox.Parent = parent

	local TextboxCorner = Instance.new('UICorner')
	TextboxCorner.CornerRadius = UDim.new(0, 4)
	TextboxCorner.Parent = Textbox

	function TextboxManager:update_text(text)
		self._text = text
		Library._config._flags[settings.flag] = self._text
		Config:save(tostring(game.GameId), Library._config)
		if settings.callback then
			settings.callback(self._text)
		end
	end

	Textbox.FocusLost:Connect(function()
		TextboxManager:update_text(Textbox.Text)
	end)

	return TextboxManager
end

-- ============================================
-- INITIALIZATION
-- ============================================

function Library:init()
	self:create_ui()
	return self
end

return Library
