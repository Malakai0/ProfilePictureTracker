local Discord = require('discordia');
local Client = Discord.Client()
local Http = require('coro-http');
local Timer = require('timer');

Discord.extensions();

local Interval = 5; -- Seconds

local Token = io.open('token.txt', 'r'):read('*a')
local Tracking = {
    '283009043168231425'; -- Infernus!
}
local TrackedPictures = {}

local function GetProfilePictureDirectory(UserID)
    return string.format('./%s', UserID)
end

local function GetUsername(UserID)
    return Client:getUser(UserID).name;
end

local function CreateFolder(Name)
    local directory = string.format('./%s/CREATED.tmp', Name)
    local temp_find = io.open(directory, 'r');
    if (temp_find) then
        io.close(temp_find)
        return true;
    else
        os.execute(string.format('mkdir "%s"', Name))

        local created = io.open(directory, 'w')
        created:write('this file exists..');
        io.close(created);

        return true;
    end
end

local function SaveProfilePicture(Name, URL)
    CreateFolder(Name)
    local Directory = GetProfilePictureDirectory(Name)
    local Sliced = URL:split('/')
    local Image = Sliced[#Sliced]
    local ImageDirectory = string.format('%s/%s', Directory, Image);

    local _,ImageData = Http.request('GET', URL)

    local ImageFile = io.open(ImageDirectory, 'wb');
    ImageFile:write(ImageData);
    ImageFile:close();

    print(string.format('Wrote new profile picture for %s', Name));
end

local function TrackChange(UserID)

    local Current = Client:getUser(UserID).avatarURL
    local Last = TrackedPictures[UserID]

    local Name = GetUsername(UserID)
    if (not Last) then
        SaveProfilePicture( Name, Current )
        print(string.format('First PFP for %s: %s', GetUsername(UserID), Current))

        TrackedPictures[UserID] = Current;
        return true;
    end

    if (Current ~= Last) then
        SaveProfilePicture(Name, Client:getUser(UserID).avatarURL)
        TrackedPictures[UserID] = Client:getUser(UserID).avatarURL;

        print(string.format('%s changed their PFP: %s', GetUsername(UserID), Last));
        return true;
    end

    return false;
end

local function UpdateChanges()
    for _, UserID in next, Tracking do
        coroutine.wrap(function()
            
            TrackChange(UserID);

        end)()
    end
end

Client:on('ready', function()
    print('Started Inferny!')

    Timer.setInterval(Interval*1000, function()
        coroutine.wrap(UpdateChanges)()
    end)

end)

Client:run(string.format('Bot %s', Token));