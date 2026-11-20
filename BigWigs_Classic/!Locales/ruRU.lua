if not BigWigsAPI.IsLocale("ruRU") then return end -- 3.3.5: no [TextLocale] in .toc files
-- Texts from DBM Sirus (DBM-MC, DBM-BWL, DBM-AQ20, DBM-AQ40, DBM-ZG: localization.ru.lua)

-- Molten Core

BigWigsAPI.SetBossModuleLocale("Majordomo Executus", {
	shield = "Следующий Щит",
	shield_desc = "Показывать таймер для следующего Щита (Damage/Reflect)",
})

BigWigsAPI.SetBossModuleLocale("Ragnaros Classic", {
	submerge_trigger = "ПРИДИТЕ, МОИ СЛУГИ! ЗАЩИТИТЕ СВОЕГО ХОЗЯИНА!",
	pull_trigger = "Нахальные щенки! Вы сами обрекли себя на смерть! Узрите же Повелителя в гневе!",

	submerge = "Погружение",
	submerge_desc = "Показывать предупреждение о погружении и время до погружения",
	emerge = "Появление",
	emerge_desc = "Показывать предупреждение о появлении и время до появления",
})

-- Blackwing Lair

BigWigsAPI.SetBossModuleLocale("Razorgore the Untamed", {
	engage_trigger = "Враги в инкубаторе! Бейте тревогу! Защищайте яйца любой ценой!",
	stage2_trigger = "убегает, как только сила сферы пошла на спад.",

	adds = "Появление аддов",
	adds_desc = "Показывать таймер до первого появления аддов",
})

BigWigsAPI.SetBossModuleLocale("Vaelastrasz the Corrupt", {
	warmup_trigger = "Слишком поздно, друзья мои! Порча Нефария подчинила меня... Я не могу... справиться с собой.",
})

BigWigsAPI.SetBossModuleLocale("Broodlord Lashlayer", {
	engage_trigger = "Таких, как вы, здесь быть не должно! Смерть грозит лишь вам!",
})

BigWigsAPI.SetBossModuleLocale("Chromaggus", {
	breath = "Дыхание",
	breath_desc = "Показывать предупреждение о дыханиях Хромаггуса, применение и время восстановления дыханий",
	breath1 = "Первое Дыхание",
	breath2 = "Второе Дыхание",
	breath_cd = "%s восстановление",

	vulnerability = "Уязвимость",
	vulnerability_desc = "Показывать восстановление уязвимости",
	vulnerability_trigger = "%s уходит, мерцая.",
	vulnerability_cd = "Восстановление уязвимости",
})

BigWigsAPI.SetBossModuleLocale("Nefarian Classic", {
	engage_trigger = "Да начнутся игры!",
	stage2_trigger = "Браво, слуги мои! Смертные утрачивают мужество! Поглядим же, как они справятся с истинным Повелителем Черной горы!!!",
	stage3_trigger = "Не может быть! Восстаньте, мои прислужники! Послужите господину еще раз!",
	shaman_trigger = "Шаманы, покажите, на что способны ваши тотемы!",
	paladin_trigger = "Паладины… Я слышал, у вас несколько жизней. Докажите.",
	druid_trigger = "Друиды и их дурацкие превращения… Ну что ж, поглядим!",
	priest_trigger = "Жрецы! Если вы собираетесь продолжать так лечить, то давайте хоть немного разнообразим процесс!",
	warrior_trigger = "Воины! Я знаю, вы можете бить сильнее! Ну-ка, покажите!",
	rogue_trigger = "Разбойники? Хватит прятаться, покажитесь!",
	warlock_trigger = "Чернокнижники, ну не беритесь вы за волшебство, которого сами не понимаете! Видите, что получилось?",
	hunter_trigger = "Охотники со своими жалкими пугачами!",
	mage_trigger = "И маги тоже? Осторожнее надо быть, когда играешь с магией…",
	-- deathknight_trigger: no Russian text in DBM Sirus

	classcall = "Классовый зов",
	classcall_desc = "Объявлять классовый вызов и показывать таймер классовых вызовов",
	classcall_warning = "Дебафф на %s",
	classcall_you = "Классовый зов на тебе!",
	classcall_ends = "%s зов заканчивается",

	adds_left = "Адды",
	adds_left_desc = "Объявлять, сколько убийств осталось до 2-й фазы",
	adds_left_message = "Осталось %d убийств",
})

-- Ruins of Ahn'Qiraj

BigWigsAPI.SetBossModuleLocale("General Rajaxx", {
	wave12_trigger = "Они пришли. Постарайся не дать себя убить, ", -- DBM: key Wave1
	wave12alt_trigger = "Раджакс, напомни, когда я в последний раз обещал тебя убить?",
	wave3_trigger = "Час возмездия близок! Да охватит мрак сердца наших врагов!",
	wave4_trigger = "Мы не будем больше ждать за закрытыми дверьми и каменными стенами! Мы не будем больше отказываться от возмездия! Даже драконы содрогнутся перед нашим гневом!",
	wave5_trigger = "Пусть наши враги трепещут! Смерть им!",
	wave6_trigger = "Олений Шлем будет скулить и молить о пощаде, в точности как его сопливый сынок! Тысячелетняя несправедливость сегодня закончится!",
	wave7_trigger = "Фэндрал! Твой час пробил! Иди же, прячься в изумрудном сне и молись, чтобы мы до тебя не добрались!",
	wave8_trigger = "Настырная тварь! Я сам тебя убью!",

	waves = "Волны",
	waves_desc = "Показывать предупреждение о следующей волне",
	wave = "Волна %s",
})

BigWigsAPI.SetBossModuleLocale("Buru the Gorger", {
	pursue_trigger = "%s смотрит на",

	pursue = "Преследование",
	pursue_desc = "Показывать специальное предупреждение, когда преследование на вас, называть преследуемые цели",
	pursue_other = "Преследует >%s<",
	pursue_you = "Преследует вас!",
})

BigWigsAPI.SetBossModuleLocale("Ossirian the Unscarred", {
	weakness = "Слабость",
	weakness_desc = "Объявлять слабость, показывать таймер до слабости",
})

-- Temple of Ahn'Qiraj

BigWigsAPI.SetBossModuleLocale("Viscidus", {
	slow_trigger = "замедляется!",
	freezing_trigger = "замораживается!",
	frozen_trigger = "застывает!",
	crack_trigger = "начинает раскалываться!",
	shatter_trigger = "едва держится!",
	explode_trigger = "взрывается!",

	freeze = "Заморозка",
	freeze_desc = "Объявлять статус Заморозки",
	freeze_message = "Заморожен: %d/3",
	shatter = "Раскол",
	shatter_desc = "Объявлять статус Раскола",
	shatter_message = "Расколот: %d/3",
})

BigWigsAPI.SetBossModuleLocale("Ouro", {
	submerge = "Закапывание",
	submerge_desc = "Показывать предупреждение о закапывании и таймер до закапывания",
	submerge_bar = "Закапывание",
	emerge = "Появление",
	emerge_desc = "Показывать предупреждение о появлении и таймер до появления",
})

BigWigsAPI.SetBossModuleLocale("C'Thun", {
	weakened_trigger = "ослаблен!",

	eye_tentacle = "Глазной отросток",
	eye_tentacle_desc = "Показывать предупреждение и таймер до следующего Глазного отростка",
	claw_tentacle = "Когтещупальце",
	claw_tentacle_desc = "Показывать предупреждение и таймер до следующего Когтещупальца",
	giant_eye_tentacle = "Огромное глазастое щупальце",
	giant_eye_tentacle_desc = "Показывать предупреждение и таймер до следующего Огромного глазастого щупальца",
	giant_claw_tentacle = "Гигантский когтещуп",
	giant_claw_tentacle_desc = "Показывать предупреждение и таймер до следующего Гигантского когтещупа",
	weakened = "К'Тун ослаблен!",
	weakened_desc = "Показывать специальное предупреждение, когда босс ослаблен, и таймер продолжительности ослабления",
	weakened_bar = "Ослаблен закончен",
})

-- Zul'Gurub (no journal ids: the names are from the DBM locale)

BigWigsAPI.SetBossModuleLocale("High Priest Venoxis", {
	bossName = "Верховный жрец Веноксис",
})

BigWigsAPI.SetBossModuleLocale("High Priestess Jeklik", {
	bossName = "Верховная жрица Джеклик",
})

BigWigsAPI.SetBossModuleLocale("High Priestess Mar'li", {
	bossName = "Верховная жрица Мар'ли",
})

BigWigsAPI.SetBossModuleLocale("Bloodlord Mandokir", {
	bossName = "Мандокир Повелитель Крови",
	gaze_trigger = "Я за тобой слежу",
})

BigWigsAPI.SetBossModuleLocale("Edge of Madness", {
	bossName = "Грань Безумия",
})

BigWigsAPI.SetBossModuleLocale("High Priest Thekal", {
	bossName = "Верховный жрец Текал",
	priest_died_trigger = "%s умирает.",
	stage2_trigger = "Ширвалла, наполни меня своим ГНЕВОМ!",
	win_trigger = "Хаккар больше не властен надо мной! Наконец-то я обрел покой!",

	resurrection = "Воскрешение",
	resurrection_desc = "Объявлять о смерти первого адда, показывать время до воскрешения жреца",
	resurrection_message = "Первый адд пал - воскрешение через ~15 сек.",
})

BigWigsAPI.SetBossModuleLocale("High Priestess Arlokk", {
	bossName = "Верховная жрица Арлокк",
})

BigWigsAPI.SetBossModuleLocale("Gahz'ranka", {
	bossName = "Газ'ранка",
})

BigWigsAPI.SetBossModuleLocale("Jin'do the Hexxer", {
	bossName = "Мастер проклятий Джин'до",
})

BigWigsAPI.SetBossModuleLocale("Hakkar the Soulflayer", {
	bossName = "Хаккар",
})
