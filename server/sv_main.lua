local function formatCoords(coords)
    local x, y, z, w = coords.x, coords.y, coords.z, (coords.w or 0)
    return vec4(x, y, z, w)
end

lib.callback.register('qbx_spawn:server:getHouses', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    local houseData = {}
    local playerHouses = MySQL.query.await('SELECT * FROM properties WHERE owner = ?', { player.PlayerData.citizenid })

    for i = 1, #playerHouses do
        local name = playerHouses[i].property_name
        local id = playerHouses[i].id
        local locationData = MySQL.single.await('SELECT `coords`, `property_name` FROM properties WHERE id = ?', { id })
        houseData[#houseData+1] = {
            label = locationData.property_name,
            coords = formatCoords(json.decode(locationData.coords))
        }
    end

    return houseData
end)