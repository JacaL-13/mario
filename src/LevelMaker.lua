--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]] LevelMaker = Class {}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND

    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    local keyLocation = math.random(10, width - 10)
    local lockLocation = math.random(10, width - 10)

    local keyColor = math.random(4)

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y], Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x > 1 then
            for y = 7, height do
                table.insert(tiles[y], Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            -- maximum key height to avoid spawing in the ground
            local maxKeyHeight = 6
            local minKeyHeight = 3

            for y = 7, height do
                table.insert(tiles[y], Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x > 1 then
                blockHeight = 2
                maxKeyHeight = 4
                minKeyHeight = 1

                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects, GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (4 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- select random frame from bush_ids whitelist, then random row for variance
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    })
                end

                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)

                tiles[7][x].topper = nil

                -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects, GameObject {
                    texture = 'bushes',
                    x = (x - 1) * TILE_SIZE,
                    y = (6 - 1) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                    collidable = false
                })
            end

            local blockSpawned = false

            if lockLocation == x then
                table.insert(objects, GameObject {
                    texture = 'keys-locks',
                    x = (x - 1) * TILE_SIZE,
                    y = (4 - 1) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = keyColor + 4,
                    collidable = true,
                    consumable = false,
                    solid = true,
                    keyblock = true,
                    onCollide = function(player, object)
                        print('player.hasKey: ' .. tostring(player.hasKey))
                    end,
                    onConsume = function(player, object)
                        gSounds['pickup']:play()
                        player.hasKey = false

                        print('player.hasKey: ' .. tostring(player.hasKey))
                    end
                })
            elseif math.random(10) == 1 then -- chance to spawn a block
                table.insert(objects, -- jump block
                GameObject {
                    texture = 'jump-blocks',
                    x = (x - 1) * TILE_SIZE,
                    y = (blockHeight - 1) * TILE_SIZE,
                    width = 16,
                    height = 16,

                    -- make it a random variant
                    frame = math.random(#JUMP_BLOCKS),
                    collidable = true,
                    hit = false,
                    solid = true,

                    -- collision function takes itself
                    onCollide = function(player, object)

                        -- spawn a gem if we haven't already hit the block
                        if not object.hit then

                            -- chance to spawn gem, not guaranteed
                            if math.random(5) == 1 then

                                -- maintain reference so we can set it to nil
                                local gem = GameObject {
                                    texture = 'gems',
                                    x = (x - 1) * TILE_SIZE,
                                    y = (blockHeight - 1) * TILE_SIZE - 4,
                                    width = 16,
                                    height = 16,
                                    frame = math.random(#GEMS),
                                    collidable = true,
                                    consumable = true,
                                    solid = false,

                                    -- gem has its own function to add to the player's score
                                    onConsume = function(player, object)
                                        gSounds['pickup']:play()
                                        player.score = player.score + 100
                                    end
                                }

                                -- make the gem move up from the block and play a sound
                                Timer.tween(0.1, {
                                    [gem] = {
                                        y = (blockHeight - 2) * TILE_SIZE
                                    }
                                })
                                gSounds['powerup-reveal']:play()

                                table.insert(objects, gem)
                            end

                            object.hit = true
                        end

                        gSounds['empty-block']:play()
                    end
                })

                maxKeyHeight = maxKeyHeight - 1
                minKeyHeight = 1

                blockSpawned = true
            end

            if x == keyLocation then

                local keyHeight = math.random(minKeyHeight, maxKeyHeight)
                print('keyHeight: ' .. keyHeight)

                if blockSpawned and keyHeight >= blockHeight then
                    keyHeight = keyHeight - 1
                end

                table.insert(objects, GameObject {
                    texture = 'keys-locks',
                    x = (x - 1) * TILE_SIZE,
                    y = (keyHeight - 1) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = keyColor,
                    collidable = true,
                    consumable = true,
                    solid = false,
                    onConsume = function(player, object)
                        gSounds['pickup']:play()
                        player.hasKey = true

						-- loop through all objects and turn the lock consumable and not collidable
						for k, object in pairs(objects) do
							print('object.keyblock: ' .. tostring(object.keyblock))
							
							if object.keyblock then
								object.consumable = true
								object.collidable = false
								object.solid = false
							end
						end

                        print('player.hasKey: ' .. tostring(player.hasKey))
                    end
                })

            end

        end
    end
    print('key spawned at: ' .. keyLocation)

    local map = TileMap(width, height)
    map.tiles = tiles

    return GameLevel(entities, objects, map)
end
