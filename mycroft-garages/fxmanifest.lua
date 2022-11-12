fx_version 'cerulean'
game 'gta5'

name "mycroft-garages"
description "A simple Garage resource for ESX Legacy"
author "Mycroft - Vice President Of ESX-Framework"
version "0.1.0"

shared_scripts {
	'@es_extended/imports.lua',
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}
