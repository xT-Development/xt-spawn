fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

description "Ox_lib Spawn Menu for QBX | xT Development "

shared_scripts { '@ox_lib/init.lua' }
client_scripts { 'client/*.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/*.lua' }
files { 'configs/*.lua' }

provide 'qbx_spawn'