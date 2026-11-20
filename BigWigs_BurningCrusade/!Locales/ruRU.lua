if not BigWigsAPI.IsLocale("ruRU") then return end -- 3.3.5: no [TextLocale] in .toc files
-- Texts from DBM Sirus (DBM-Karazhan, DBM-Gruul, DBM-Magtheridon, DBM-Serpentshrine, DBM-TheEye, DBM-Hyjal, DBM-BlackTemple, DBM-ZulAman, DBM-Sunwell: localization.ru.lua)

-- Karazhan

BigWigsAPI.SetBossModuleLocale("Attumen the Huntsman", {
	mount_trigger = "Давай, Полночь, разгоним этот сброд!",
})

BigWigsAPI.SetBossModuleLocale("The Big Bad Wolf", {
	bossName = "Злой и страшный серый волк",
	engage_trigger = "Так вам и надо!",
})

BigWigsAPI.SetBossModuleLocale("Romulo and Julianne", {
	bossName = "Ромуло и Джулианна",
	-- warmup_trigger: no Russian text in DBM Sirus
	stage3_trigger = "Ночь, добрая и строгая, приди! Верни мне моего Ромуло!",
})

BigWigsAPI.SetBossModuleLocale("The Wizard of Oz", {
	bossName = "Страна Оз",
	engage_trigger = "О, Тито, нам просто надо найти дорогу домой!",
	-- roar/strawman/tinhead/crone triggers: DBM Sirus has the English texts in the Russian localization too

	bosses = "Спавн боссов",
	bosses_desc = "Показать предупреждение и таймер спавна босса",
	tito = "Тито",
	roar = "Хохотун",
	strawman = "Балбес",
	tinhead = "Медноголовый",
	crone = "Ведьма",
})

BigWigsAPI.SetBossModuleLocale("The Curator", {
	evocation_trigger = "Ваш запрос не может быть выполнен.",
})

BigWigsAPI.SetBossModuleLocale("Shade of Aran", {
	special = "Следующая спец-способность",
	special_desc = "Отсчет времени до следующей спец-способности",
	dont_move = "Не двигайтесь!",
})

BigWigsAPI.SetBossModuleLocale("Netherspite", {
	banish_trigger = "%s впадает в предельную ярость!",
	portal_trigger = "%s издает крик, отступая, открывая путь Пустоте.",

	portal_soon = "Фаза порталов через 5 секунд",
	banish_soon = "Фаза изгнания через 5 секунд",
	portal_phase = "Фаза порталов",
	banish_phase = "Фаза изгнания",
})

BigWigsAPI.SetBossModuleLocale("Prince Malchezaar", {
	stage2_trigger = "Глупцы! Время – это огонь, сжигающий вас!",
	stage3_trigger = "Как вы осмелились бросить вызов столь колоссальной мощи?",
	infernal_trigger1 = "Мне открыты все реальности, все измерения!",
	infernal_trigger2 = "Вы противостоите не только Мальчезаару, но и всем подвластным мне легионам!",
})

BigWigsAPI.SetBossModuleLocale("Nightbane", {
	bossName = "Ночная Погибель",
	summon_trigger = "Древнее существо пробуждается вдалеке...",
	summon = "Начало",
})

BigWigsAPI.SetBossModuleLocale("Chess Event", {
	bossName = "Шахматы",
	cheat = "Обман Медива", -- DBM: no text
	cheat_desc = "Отсчет времени до следующего обмана Медива",
})

-- Serpentshrine Cavern (most Sirus texts are only in Russian in DBM: they are the English defaults of the modules)

BigWigsAPI.SetBossModuleLocale("The Lurker Below", {
	submerge = "Погружение",
	submerge_desc = "Объявлять погружение и появление, отсчет времени до них",
	submerged = "Скоро погружение",
	emerged = "Скоро появление",
	emerge = "Появление",
})

BigWigsAPI.SetBossModuleLocale("Leotheras the Blind", {
	demon_trigger = "Прочь, жалкий эльф. Настало мое время!",
	stage2_trigger = "Нет... нет! Что вы наделали? Я – главный! Слышишь меня? Я... Ааааах! Мне его... не удержать.",

	forms = "Формы",
	forms_desc = "Отсчет времени до превращения в демона и до конца формы демона",
})

BigWigsAPI.SetBossModuleLocale("Morogrim Tidewalker", {
	murlocs = "Мурлоки",
	murlocs_desc = "Отсчет времени до вызова мурлоков",
	murlocs_soon = "Мурлоки на подходе",
})

BigWigsAPI.SetBossModuleLocale("Lady Vashj", {
	stage2_trigger = "Время пришло! Не щадите никого!",
	stage3_trigger = "Вам не пора прятаться?",

	strider = "Странник",
	elemental = "Нечистый элементаль",
	naga = "Гвардеец",
	elemental_soon = "Нечистый элементаль на подходе",
})

-- Tempest Keep

BigWigsAPI.SetBossModuleLocale("Al'ar", {
	platform = "След. платформа",
	platform_desc = "Отсчет времени до перелета на следующую платформу",
})

BigWigsAPI.SetBossModuleLocale("High Astromancer Solarian", {
	adds_trigger = "Вы безнадежно слабы!",
	priests_trigger = "Я навсегда избавлю вас от мании величия!",

	agents = "Вызов послушников",
	priests = "Вызов жрецов",
})

BigWigsAPI.SetBossModuleLocale("Kael'thas Sunstrider", {
	engage_trigger1 = "Мне очень жаль, но вы не сможете ничего изменить. Теперь меня никто не остановит! Селама ашаль-аноре!",
	engage_trigger2 = "Мне очень жаль, но вы не сможете ничего изменить. Теперь меня никто не остановит! Селама ашаль-аноре!",
	sanguinar_trigger = "Вы справились с моими лучшими советниками... Но перед мощью Кровавого Молота не устоит никто. Узрите лорда Сангвинара!",
	capernian_trigger = "Каперниан проследит, чтобы вы не задержались здесь надолго.",
	telonicus_trigger = "Неплохо, теперь вы можете потягаться с моим главным инженером Телоникусом.",
	stage2_trigger = "Как видите, оружия у меня предостаточно...",
	stage3_trigger = "Возможно, я недооценил вас. Было бы несправедливо заставлять вас драться с четырьмя советниками сразу, но... Мои люди тоже никогда не знали справедливости. Я лишь возвращаю долг.",
	stage4_trigger = "Увы, иногда приходится брать все в свои руки. Баламоре шаналь!",
	stage5_trigger = "Я не затем ступил на этот путь, чтобы остановиться на полдороги! Мои планы должны сбыться – и они сбудутся! Узрите же истинную мощь!",
	gaze_trigger = "смотрит на |3%-3%(([%w\128-\255]+)%).", -- DBM TalaTarget with a capture of the name

	thaladred = "Таладред",
	sanguinar = "Лорд Сангвинар",
	capernian = "Каперниан",
	telonicus = "Телоникус",

	gaze = "Взгляд Таладреда",
	gaze_desc = "Обьявлять цели преследуемые Таладредом",
	gaze_msg = "Таладред преследует %s",
	gaze_bar = "Смена цели Таладреда",
})

-- Hyjal Summit (the boss texts of the Sirus version are only in Russian in DBM: they are the English defaults of the modules)

BigWigsAPI.SetBossModuleLocale("Hyjal Summit Trash", {
	wave_check = "Текущая атака: (%d+) из 5",
	wave_msg = "Волна %s/5",
	next_wave = "Следующая волна",
	rage_gossip = "Леди Праудмур, мертвецы построили еще один лагерь. В скором времени они начнут атаковать нас. Мы готовы помочь!",
	anetheron_gossip = "Мы готовы встретить любого, кого пошлет Архимонд, леди Праудмур.",
	kazrogal_gossip = "Я с тобой, Тралл.",
	azgalor_gossip = "Нам нечего бояться.",

	waves = "Волны",
	waves_desc = "Предупреждать о новой волне и показывать таймер следующей волны",
})

-- Black Temple (the texts of the Sirus versions are only in Russian in DBM: they are the English defaults of the modules)

BigWigsAPI.SetBossModuleLocale("Reliquary of Souls", {
	anger = "Воплощение Гнева",
	desire = "Воплощение Желания",
	suffering = "Воплощение Страдания",
})

BigWigsAPI.SetBossModuleLocale("Mother Shahraz", {
	bossName = "Матушка Шахраз",
})

BigWigsAPI.SetBossModuleLocale("Illidan Stormrage", {
	warmup_trigger = "Акама! Твое двуличие меня не удивляет. Мне давным-давно стоило уничтожить тебя и твоих уродливых собратьев.",
	eyebeam_trigger = "Посмотри в глаза Предателя!",
	demon_trigger = "Узрите мощь демона!",
	stage4_trigger = "Это все, смертные? Это и есть вся ваша ярость?",

	forms = "Формы",
	forms_desc = "Предупреждения и таймеры обычной фазы и фазы демона",
	human = "Обычная фаза",
	demon = "Фаза демона",
	next_human = "Следующая обычная фаза",
	next_demon = "Следующая фаза демона",
})

-- Zul'Aman

BigWigsAPI.SetBossModuleLocale("Nalorakk", {
	bear_trigger = "Хотели разбудить во мне зверя? Вам это удалось.",
	troll_trigger = "C дороги!",

	forms = "Формы",
	forms_desc = "Предупреждения и отсчет времени до формы медведя и формы тролля",
})

BigWigsAPI.SetBossModuleLocale("Jan'alai", {
	bombs_trigger = "Щас я вас сожгу!",
	hatchers_trigger = "Эй, хранители! Займитесь яйцами!",
})

BigWigsAPI.SetBossModuleLocale("Hex Lord Malacrass", {
	engage_trigger = "Тьма поглотит вас!",

	special = "Спец. способность",
	special_desc = "Отсчитывать время между спец-способности",
})

BigWigsAPI.SetBossModuleLocale("Zul'jin", {
	stage2_trigger = "Выучил новый фокус… прямо как братишка-медведь...",
	stage3_trigger = "От орла нигде не скрыться!",
	stage4_trigger = "Позвольте представить моих двух братцев: клык и коготь!",
	stage5_trigger = "Для того чтобы увидеть дракондора, в небо смотреть необязательно!",
})

-- Sunwell Plateau (most texts are only in Russian in DBM: they are the English defaults of the modules)

BigWigsAPI.SetBossModuleLocale("Brutallus", {
	engage_trigger = "Аа, новые овечки на заклание?",
})

BigWigsAPI.SetBossModuleLocale("Kil'jaeden", {
	engage_trigger = "Те, кем можно было пожертвовать, мертвы. Так тому и быть! Я добьюсь успеха там, где Саргерас потерпел поражение! Я заставлю этот жалкий мирок истекать кровью и навеки закреплю за собой место повелителя Пылающего Легиона! Пробил последний час этого мира!",
	orb_trigger1 = "Я наполню сферы своей энергией! Готовьтесь!",
	orb_trigger2 = "Я наполнил энергией еще одну сферу! Быстрее используйте ее!",
	orb_trigger3 = "Готова еще одна сфера! Торопитесь!",
	orb_trigger4 = "Я отдал все, что мог. Моя энергия в ваших руках!",
})
