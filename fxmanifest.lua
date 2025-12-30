fx_version 'cerulean'
game 'gta5'

description 'mrc-template'
version '1.0.0'

shared_scripts {
	"config.lua",
	'shared/*.lua',
	"behaviors/*.lua"
}

server_scripts {
	"@oxmysql/lib/MySQL.lua",
    'server/*.lua',
}

client_scripts {
    'client/*.lua',
}


dependencies {
	'community_bridge',
}

lua54 'yes'
