-- TODO: function to set status indicating zoomed state

local wezterm = require('wezterm')

local config = wezterm.config_builder()

-- Basic configuration
config.max_fps = 120
config.prefer_egl = true
config.font = wezterm.font_with_fallback({ 'JetBrains Mono', 'IBM Plex Mono' })
config.font_size = 11
config.color_scheme = 'Oxocarbon Dark'
config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
config.window_padding = { left = 5, right = 5, top = 10, bottom = 0 }
config.use_fancy_tab_bar = false
config.tab_max_width = 30
config.inactive_pane_hsb = { saturation = 0.75, brightness = 0.7 }

-- Handle shell application to start
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    -- Check if PowerShell 7+ is installed, otherwise fallback to Windows PowerShell
    local pwsh_path = 'C:\\Program Files\\PowerShell\\7\\pwsh.exe'
    local success, result = pcall(function()
        return wezterm.run_child_process({ pwsh_path, '-NoLogo', '-Command', 'exit' })
    end)

    if success and result then
        config.default_prog = { pwsh_path, '-NoLogo' }
    else
        config.default_prog = { 'powershell.exe', '-NoLogo' }
    end
elseif wezterm.target_triple == 'x86_64-unknown-linux-gnu' then
    config.default_prog = { '/usr/bin/bash', '--login' }
end

-- Startup
wezterm.on('gui-startup', function(window)
    local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
    local gui_window = window:gui_window()
    gui_window:maximize()
end)

-- Keybinds
config.keys = {
    { key = 't', mods = 'ALT|SHIFT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
    { key = 'm', mods = 'ALT', action = wezterm.action.TogglePaneZoomState },
    { key = '.', mods = 'ALT', action = wezterm.action.ActivateTabRelative(1) },
    { key = ',', mods = 'ALT', action = wezterm.action.ActivateTabRelative(-1) },
    { key = 'Q', mods = 'ALT', action = wezterm.action.CloseCurrentPane({ confirm = false }) },
    { key = 'n', mods = 'ALT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = 'N', mods = 'ALT', action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = 'r', mods = 'ALT', action = wezterm.action.RotatePanes('Clockwise') },
    { key = 'h', mods = 'ALT', action = wezterm.action.ActivatePaneDirection('Left') },
    { key = 'l', mods = 'ALT', action = wezterm.action.ActivatePaneDirection('Right') },
    { key = 'k', mods = 'ALT', action = wezterm.action.ActivatePaneDirection('Up') },
    { key = 'j', mods = 'ALT', action = wezterm.action.ActivatePaneDirection('Down') },
    { key = 'f', mods = 'ALT', action = wezterm.action.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }) },
    { key = 'h', mods = 'ALT|SHIFT', action = wezterm.action.MoveTabRelative(-1) },
    { key = 'l', mods = 'ALT|SHIFT', action = wezterm.action.MoveTabRelative(1) },

    -- Resize Windows
    { key = 'LeftArrow', mods = 'ALT', action = wezterm.action.AdjustPaneSize({ 'Left', 1 }) },
    { key = 'LeftArrow', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize({ 'Left', 5 }) },
    { key = 'RightArrow', mods = 'ALT', action = wezterm.action.AdjustPaneSize({ 'Right', 1 }) },
    { key = 'RightArrow', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize({ 'Right', 5 }) },
    { key = 'DownArrow', mods = 'ALT', action = wezterm.action.AdjustPaneSize({ 'Down', 1 }) },
    { key = 'DownArrow', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize({ 'Down', 5 }) },
    { key = 'UpArrow', mods = 'ALT', action = wezterm.action.AdjustPaneSize({ 'Up', 1 }) },
    { key = 'UpArrow', mods = 'ALT|SHIFT', action = wezterm.action.AdjustPaneSize({ 'Up', 5 }) },

    -- Switch to Tabs
    { key = '1', mods = 'ALT', action = wezterm.action.ActivateTab(0) },
    { key = '2', mods = 'ALT', action = wezterm.action.ActivateTab(1) },
    { key = '3', mods = 'ALT', action = wezterm.action.ActivateTab(2) },
    { key = '4', mods = 'ALT', action = wezterm.action.ActivateTab(3) },
    { key = '5', mods = 'ALT', action = wezterm.action.ActivateTab(4) },
    { key = '6', mods = 'ALT', action = wezterm.action.ActivateTab(5) },
    { key = '7', mods = 'ALT', action = wezterm.action.ActivateTab(6) },
    { key = '8', mods = 'ALT', action = wezterm.action.ActivateTab(7) },
    { key = '9', mods = 'ALT', action = wezterm.action.ActivateTab(8) },
    { key = '8', mods = 'ALT', action = wezterm.action.ActivateTab(9) },

    -- Disable Keybinds
    { key = 'N', mods = 'CTRL', action = wezterm.action.DisableDefaultAssignment },
    {
        key = 'p',
        mods = 'ALT',
        action = wezterm.action_callback(function(window, pane)
            project_layouts.vf8(window, pane)
        end),
    },
}

local function is_app_title(title)
    return #title > 0 and not title:find('^%a:\\')
end

local function get_cwd_basename(pane)
    local cwd_url = pane.current_working_dir
    if not cwd_url then
        return nil
    end

    local cwd = cwd_url.file_path or tostring(cwd_url)
    cwd = cwd:gsub('[/\\]+$', '')
    local basename = cwd:match('[/\\]([^/\\]+)$') or cwd
    if basename and #basename > 0 then
        return basename
    end
    return nil
end

local function has_claude(tab_info)
    for _, pane_info in ipairs(tab_info.panes) do
        if ((pane_info.title or ''):lower()):find('claude') then
            return true
        end
    end
    return false
end

local function resolve_tab_title(tab_info)
    -- prefer explicit title
    local explicit = tab_info.tab_title
    if explicit and #explicit > 0 then
        return explicit, true
    end

    -- then app title
    local pane_title = tab_info.active_pane.title or ''
    if is_app_title(pane_title) and not pane_title:lower():find('claude') then
        return pane_title, false
    end

    -- then cwd basename
    return get_cwd_basename(tab_info.active_pane) or pane_title, false
end

local function pad_title(title, max_w)
    if #title > max_w then
        return wezterm.truncate_right(title, max_w - 2)
    end
    local padding = math.floor((max_w - #title) / 2)
    return string.rep(' ', padding) .. title .. string.rep(' ', max_w - #title - padding)
end

local tab_colors = {
    fg_active = '#78a9ff',
    bg_active = '#161616',
    fg_inactive = '#d0d0d0',
    bg_inactive = '#262626',
    idx_active = '#78a9ff',
    idx_inactive = '#705d99',
}

wezterm.on('format-tab-title', function(tab, tabs, panes, conf, hover, max_width)
    local title, is_explicit = resolve_tab_title(tab)

    if not is_explicit and has_claude(tab) then
        title = 'C - ' .. title
    end

    local padded = pad_title(title, max_width - 4)
    local active = tab.is_active

    return {
        { Background = { Color = active and tab_colors.idx_active or tab_colors.idx_inactive } },
        { Foreground = { Color = tab_colors.bg_inactive } },
        { Text = ' ' .. tab.tab_index + 1 .. ' ' },
        { Background = { Color = active and tab_colors.bg_active or tab_colors.bg_inactive } },
        { Foreground = { Color = active and tab_colors.fg_active or tab_colors.fg_inactive } },
        { Text = padded },
    }
end)

return config
