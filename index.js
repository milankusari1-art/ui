const Net = require("net");
const Zlib = require("zlib");

// Roblox UI Script (Blue Theme)
const RobloxUI = `
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("EuphoriaBlueUI"):Destroy()
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EuphoriaBlueUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 320, 0, 260)
Main.Position = UDim2.new(0.5, -160, 0.5, -130)
Main.BackgroundColor3 = Color3.fromRGB(20, 35, 70)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "Euphoria Blue UI"
Title.TextColor3 = Color3.new(1,1,1)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Main

local function createButton(text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 40)
    btn.Position = UDim2.new(0.075, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.Text = text
    btn.Parent = Main
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    return btn
end

local FlyButton = createButton("Fly: OFF", 60)
local ESPButton = createButton("ESP: OFF", 110)
local SpeedButton = createButton("WalkSpeed: 16", 160)
local CloseButton = createButton("Close", 210)

local flyEnabled = false
local espEnabled = false
local walkSpeed = 16

FlyButton.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    FlyButton.Text = "Fly: " .. (flyEnabled and "ON" or "OFF")
end)

ESPButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPButton.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

SpeedButton.MouseButton1Click:Connect(function()
    walkSpeed = walkSpeed + 16
    if walkSpeed > 100 then walkSpeed = 16 end
    SpeedButton.Text = "WalkSpeed: " .. walkSpeed
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid").WalkSpeed = walkSpeed
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)
`;

async function execute(Code, Port) {
    const Ports = ["8392", "8393", "8394", "8395", "8396", "8397"];
    let ConnectedPort = null;
    let Stream = null;

    for (const P of (Port === "ALL" ? Ports : [Port])) {
        try {
            Stream = await new Promise((resolve, reject) => {
                const Socket = Net.createConnection({ host: "127.0.0.1", port: parseInt(P, 10) }, () => resolve(Socket));
                Socket.on("error", reject);
            });

            console.log(`Successfully connected to Opiumware on port: ${P}`);
            ConnectedPort = P;
            break;
        } catch (err) {
            console.log(`Failed to connect to port ${P}: ${err.message}`);
        }
    }

    if (!Stream) {
        return "Failed to connect on all ports";
    }

    if (Code !== "NULL") {
        try {
            await new Promise((resolve, reject) => {
                Zlib.deflate(Buffer.from(Code, "utf8"), (err, compressed) => {
                    if (err) return reject(err);

                    Stream.write(compressed, writeErr => {
                        if (writeErr) return reject(writeErr);
                        console.log(`Script sent (${compressed.length} bytes)`);
                        resolve();
                    });
                });
            });
        } catch (err) {
            Stream.destroy();
            return `Error sending script: ${err.message}`;
        }
    }

    Stream.end();
    return `Successfully connected to Opiumware on port: ${ConnectedPort}`;
}

execute("OpiumwareScript " + RobloxUI, "ALL")
    .then(result => console.log("Result:", result))
    .catch(err => console.error("Error:", err));
