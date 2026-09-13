local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local myplot = nil

for _, plot in pairs(workspace.Plots.Claimed:GetChildren()) do
  if plot:FindFirstChild("Label") and plot.Label:FindFirstChild("BillboardGui") then
    local PlayerUI = plot.Label.BillboardGui:FindFirstChild("PlayerName")
    if PlayerUI.Text == LocalPlayer.Name or PlayerUI.Text == LocalPlayer.DisplayName then
      myplot = plot
      print("เจอละ")
      break
    end    
  end
end
