Stat effects on Crazy Diamond:
	+Move Speed: Affects the range at which CD will acquire new targets in the middle of a punch flurry
	+Range: Affects how far from the position of launch CD will travel
	+Tears: Affects how quickly CD charges up his attacks. Usually, it takes 7 tear shots to charge.
	+Shot Speed: Affects knockback of CD's punches
	+Damage: Affects CD's punch damage
	+Luck: Affects luck based tear effects in CD's punches and the chance to be able to revive things in special ways
	
Troubleshooting:	
	If the mod basically doesn't work at all, it's most likely due to a conflict with another mod, and disabling mods until you find which one it is will likely fix it. Still, feel free to contact me (melon) with any type of bug report or issue, and I will be doing what I can to fix bugs and ensure compatibility with the bulk of other mods. I'm not sure how the mod behaves with macs, but the Mac Compatibility Mod available on the workshop is likely to fix any mac specific problems if they exist.
	
Changing settings and values:
	Within the main.lua file are several custom settings which may easily be changed from 'true' to 'false' or vice versa, as well as some more minute balance values. Their effects are as follows:
		+ReapplyCostume (enabled by default): If enabled, Josuke's clothes and hair will return as soon as he walks into a new room if another costume replaced them.
		+VisibleTarget (disabled by default): Shows a target on the ground which helps illustrate where Crazy Diamond is aiming and whether he is locked on to an enemy.
		+ForceSeed (enabled by default): Enables the 'kids mode' seed which is a special seed that makes coop babies invincible. Its practical purpose is to intentionally disable achievements while playing as Josuke because a bug in AB+ can cause the game to crash when killing certain bosses with a modded character if achievements are not disabled. If you want to be able to earn achievements as Josuke, you can disable this setting, but you will risk crashing. If you want to play coop without an invincible partner, I suggest disabling the setting and inputting a seed or enabling an easter egg ingame beforehand.
		+JosukeOnly (enabled by default): Ensures that Crazy Diamond only appears and works when the player is Josuke. If disabled, any character in the game will always have a fully functional Crazy Diamond alongside them, but without Josuke's weaknesses it would very likely be overpowered unless you tweak some other values.
		+NoShooting (disabled by default): Entirely prevents the player from shooting tears normally unless he stands still for several seconds. The "NoShootingChargeMult" value multiplies the rate at which CD charges when this is enabled in order to compensate for the DPS loss, but by default this is still more difficult than playing normally. Remember, if you have to shoot in order to progress, you can do so by standing completely still for several seconds.
		+Other values: Beyond the basic settings provided at the top, many values regarding balancing are also accessible, though several of their names are synergy spoilers. With these, if you're careful, you can make the game a little more hard or easy or wacky. If you change these, make sure you only change the numbers and don't delete the commas. If the game stops working after changing anything, I suggest simply deleting and redownloading. Have fun!