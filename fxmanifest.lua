fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AZ Scripts'
description 'XP and Level System for QBCore'
version '1.0.1'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core',
    --'es_extended',
    'oxmysql'
}


