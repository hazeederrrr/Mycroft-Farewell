fx_version 'cerulean'
game 'gta5'

name "mycroft-pos"
description "A Point Of Sale Creator ting"
author "Mycroft"
version "1.0.0"
lua54 'yes'
shared_scripts {
	'@es_extended/imports.lua',
	'shared/*.lua'
}

client_scripts {
	'@meta_target/lib/target.lua',
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}
