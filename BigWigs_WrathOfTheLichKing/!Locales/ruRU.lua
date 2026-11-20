if not BigWigsAPI.IsLocale("ruRU") then return end -- 3.3.5: no [TextLocale] in .toc files
-- Texts from DBM Sirus (DBM-Ulduar, DBM-Coliseum, DBM-Icecrown, DBM-Naxx, DBM-Onyxia, DBM-EyeOfEternity, DBM-ChamberOfAspects, DBM-VoA: localization.ru.lua)

-- Ulduar

BigWigsAPI.SetBossModuleLocale("Flame Leviathan", {
	pursue_trigger = "%%s наводится на (%S+)%.",

	pursue = "Преследуется %s",
	pursue_soon = "Смена цели через 5 секунд",
	ward_of_life = "Призыв Защитника жизни",
})

BigWigsAPI.SetBossModuleLocale("Razorscale", {
	engage_trigger = "Дайте время подготовить пушки.",
	air_trigger = "Огонь прекратился! Надо починить пушки!",
	ground_trigger = "Быстрее! Сейчас она снова взлетит!",
	stage2_trigger = "%%s обессилела и больше не может летать!",

	turrets = "Гарпунные пушки",
	turrets_desc = "Предупреждение для пушек",
	turret = "Гарпунная пушка %d",
	turrets_soon = "Гарпунные пушки будут собраны через 20 секунд",
	turrets_ready = "Гарпунные пушки собраны",
	grounded = "На земле",
	grounded_desc = "Отсчет времени для наземной фазы",
})

BigWigsAPI.SetBossModuleLocale("The Assembly of Iron", {
	steelbreaker = "Сталелом",
	molgeim = "Мастер рун Молгейм",
	brundir = "Буревестник Брундир",
})

BigWigsAPI.SetBossModuleLocale("Kologarn", {
	eyebeam_whisper = "%s устремляет на вас свой взгляд!",

	left_arm = "Возрождение левой руки",
	left_arm_desc = "Отсчет времени до Возрождения левой руки",
	right_arm = "Возрождение правой руки",
	right_arm_desc = "Отсчет времени до Возрождения правой руки",
	disarmed = "Обезоружен",
	disarmed_desc = "Отсчет времени для достижения Обезоружен",
})

BigWigsAPI.SetBossModuleLocale("Auriaya", {
	defender = "Возрождение Дикого защитника",
	defender_desc = "Отсчет времени до возрождения Дикого защитника",
	defender_died = "Дикий защитник погибает (осталось %d жизней)",
	defender_died_one = "Дикий защитник погибает (осталась 1 жизнь)",
})

BigWigsAPI.SetBossModuleLocale("Hodir", {
	defeat_trigger = "Наконец-то я... свободен от его оков…",
})

BigWigsAPI.SetBossModuleLocale("Thorim", {
	engage_trigger = "Незваные гости! Вы заплатите за то, что посмели вмешаться... Погодите, вы...",
	stage2_trigger = "Бесстыжие выскочки, вы решили бросить вызов мне лично? Я сокрушу вас всех!",
	defeat_trigger = "Придержите мечи! Я сдаюсь.",

	hardmode = "Сложный режим",
	hardmode_desc = "Отсчет времени для сложного режима",
})

BigWigsAPI.SetBossModuleLocale("Freya", {
	defeat_trigger = "Он больше не властен надо мной. Мой взор снова ясен. Благодарю вас, герои.",
	spawn_trigger = "Помогите мне, дети мои!",
	adds_trigger1 = "Эонар, твоей прислужнице нужна помощь!",
	adds_trigger2 = "Вас захлестнет сила стихий!",
	lifebinder_trigger = "начинает расти!",

	simul_kill = "Воскрешение",
	simul_kill_desc = "Отсчет времени до воскрешения монстров",
	simul_kill_message = "Первый помощник погиб - воскрешение через ~12 сек.",
})

BigWigsAPI.SetBossModuleLocale("Mimiron", {
	engage_trigger = "У нас мало времени, друзья! Вы поможете испытать новейшее и величайшее из моих изобретений. И учтите: после того, что вы натворили с XT-002, отказываться просто некрасиво.",
	hardmode_trigger = "Так, зачем вы это сделали? Разве вы не видели надпись \"НЕ НАЖИМАЙТЕ ЭТУ КНОПКУ!\"? Ну как мы сумеем завершить испытания при включенном механизме самоликвидации, а?",
	stage2_trigger = "ПРЕВОСХОДНО! Просто восхитительный результат! Целостность обшивки – 98,9 процента! Почти что ни царапинки! Продолжаем!",
	stage3_trigger = "Спасибо, друзья! Благодаря вам я получил ценнейшие сведения! Так, а куда же я дел... – ах, вот куда.",
	stage4_trigger = "Фаза предварительной проверки завершена. Пора начать главный тест!",
	defeat_trigger = "Очевидно, я совершил небольшую ошибку в расчетах. Пленный злодей затуманил мой разум и заставил меня отклониться от инструкций. Сейчас все системы в норме. Конец связи.",

	leviathan = "Левиафан II",
	vx001 = "VX-001",
	aerial = "Воздушное судно",

	hardmode = "Сложный режим - Самоуничтожение",
	hardmode_desc = "Отсчет времени для сложного режима",
	magnetic_core = "Магнитное ядро у %s",
	magnetic_core_desc = "Объявлять подобравших Магнитное ядро",
	bomb_bot = "Бомбот",
})

BigWigsAPI.SetBossModuleLocale("General Vezax", {
	animus = "Саронитовый враг",
	animus_desc = "Отсчет времени до появления Саронитового врага (сложный режим)",
})

BigWigsAPI.SetBossModuleLocale("Yogg-Saron", {
	engage_trigger = "Скоро мы сразимся с главарем этих извергов! Обратите гнев и ненависть против его прислужников!",

	guardian = "Страж %d",
	crusher_tentacle = "Тяжёлое щупальце",
	sanity = "Осталось %d Здравомыслия",
	madness_out = "Доведение до помешательства заканчивается - выбегайте",
	portal = "Провал Безумия",
	portal_desc = "Отсчёт времени до следующего Провала Безумия",
	portal_soon = "Провал Безумия через 3 секунды",
})

BigWigsAPI.SetBossModuleLocale("Algalon the Observer", {
	defeat_trigger = "Я видел миры, охваченные пламенем Творцов. Их жители гибли, не успев издать ни звука. Я был свидетелем того, как галактики рождались и умирали в мгновение ока. И все время я оставался холодным... и безразличным. Я. Не чувствовал. Ничего. Триллионы загубленных судеб. Неужели все они были подобны вам? Неужели все они так же любили жизнь?",
	collapsing_star_trigger = "%s призывает вспыхивающие звезды!",

	collapsing_star = "Вспыхивающая звезда",
	collapsing_star_desc = "Отсчет времени до появления Вспыхивающей звезды",
	star_low = "У Вспыхивающей звезды мало здоровья",
	cosmic_smash = "Кара небесная - взрыв через 4 секунды",
})

-- Trial of the Crusader

BigWigsAPI.SetBossModuleLocale("The Northrend Beasts", {
	warmup_trigger = "Из самых глубоких и темных пещер Грозовой Гряды был призван Гормок Пронзающий Бивень! В бой, герои!",
	stage2_trigger = "Приготовьтесь к схватке с близнецами-чудовищами, Кислотной Утробой и Жуткой Чешуей!",
	stage3_trigger = "В воздухе повеяло ледяным дыханием следующего бойца: на арену выходит Ледяной Рев! Сражайтесь или погибните, чемпионы!",
	charge_trigger = "^%%s глядит на (%S+) и испускает гортанный вой!",

	gormok = "Гормок Пронзающий Бивень",
	acidmaw = "Кислотная Утроба",
	dreadscale = "Жуткая Чешуя",
	icehowl = "Ледяной Рев",

	next_boss = "Прибытие следующего босса",
	next_boss_desc = "Отсчет времени до появления следующего противника",

	snobold = "Призыв снобольда-вассала на %s",
	snobold_desc = "Предупреждение о призыве Снобольда-вассала",

	submerge = "Зарывание",
	submerge_desc = "Отсчет времени до зарывания",
	emerge = "Появление",
	emerge_desc = "Отсчет времени до появления",
})

BigWigsAPI.SetBossModuleLocale("Faction Champions", {
	alliance_victory_trigger = "СЛАВА АЛЬЯНСУ!",
	horde_victory_trigger = "Это было лишь пробой того, что ждет нас в будущем! ЗА ОРДУ!",
})

BigWigsAPI.SetBossModuleLocale("The Twin Val'kyr", {
	special = "Следующая спец-способность",
	special_desc = "Отсчет времени до перезарядки спец-способности",
	special_soon = "Скоро спец-способность",
	change_color = "Смена цвета",
	switch_target = "Смена цели",
	kick_now = "Прерывание",
	twins_power = "Сила близнецов - больше исцеления на %s",
})

BigWigsAPI.SetBossModuleLocale("Anub'arak", {
	roleplay_trigger = "Король-лич понес тяжелую потерю! Вы проявили себя как бесстрашные герои Серебряного Авангарда! Мы вместе нанесем удар по Цитадели Ледяной Короны и разнесем в клочья остатки Плети! Нет такого испытания, которое мы бы не могли пройти сообща!",
	roleplay = "Представление перед падением",
	burrow_trigger = "Ауум на-л ак-к-к-к, ишшш. Вставайте, слуги мои. Время пожирать...",
	emerge_trigger = "вылезает на поверхность!",

	adds = "Новые помощники",
	adds_desc = "Отсчет времени до призыва помощников",

	submerge = "Зарывание",
	submerge_desc = "Предупреждение о зарывании",
	submerge_message = "Ануб'арак зарывается",
	submerge_soon = "Зарывание через 10 сек",
	emerge = "Появление",
	emerge_desc = "Предупреждение о появлении",
	emerge_message = "Ануб'арак появляется",
	emerge_soon = "Появление через 10 сек",
})

-- Icecrown Citadel

BigWigsAPI.SetBossModuleLocale("Lady Deathwhisper", {
	reanimated_trigger = "Восстань и обрети истинную форму!",

	adds = "Призыв помощников",
	adds_desc = "Отсчет времени до призыва помощников",
	adds_soon = "Скоро призыв помощников",

	reanimating = "Помощник воскрешается",
	reanimating_desc = "Предупреждение при воскрешении помощников",

	shade_attack = "Мстительный дух атакует вас - бегите",
})

BigWigsAPI.SetBossModuleLocale("Icecrown Gunship Battle", {
	warmup_trigger_alliance = "Запускайте двигатели! Летим навстречу судьбе.",
	warmup_trigger_horde = "Воспряньте, сыны и дочери Орды! Сегодня мы будем биться со смертельным врагом! ЛОК'ТАР ОГАР!",
	adds_trigger_alliance = "Разрушители, сержанты, в бой!",
	adds_trigger_horde = "Пехота, сержанты, в бой!",
	mage_trigger_alliance = "Корабль под обстрелом! Боевого мага сюда, пусть заткнет эти пушки!",
	mage_trigger_horde = "Корабль под обстрелом! Заклинателя сюда, пусть заткнет эти пушки!",
	defeat_trigger_alliance = "Ну не говорите потом, что я не предупреждал. В атаку, братья и сестры!",
	defeat_trigger_horde = "Альянс повержен. Вперед, к Королю-личу!",

	adds = "Призыв помощников",
	adds_desc = "Отсчет времени до новых помощников",
	adds_soon = "Скоро новые помощники",
})

BigWigsAPI.SetBossModuleLocale("Deathbringer Saurfang", {
	warmup_trigger_alliance = "Все павшие воины Орды, все дохлые псы Альянса – все пополнят армию Короля-лича. Даже сейчас валь'киры воскрешают ваших покойников, чтобы те стали частью Плети!",
	warmup_trigger_horde = "Кор'крон, выдвигайтесь! Герои, будьте начеку. Плеть только что...",
})

BigWigsAPI.SetBossModuleLocale("Rotface", {
	slime_pipes_trigger1 = "Отличные новости, народ! Я починил трубы для подачи ядовитой слизи!",
	slime_pipes_trigger2 = "Отличные новости, народ! Слизь снова потекла!",

	ooze_spawn = "Малый слизнюк",
	ooze_spawn_desc = "Предупреждение при появлении Малого слизнюка",

	little_ooze = "Малый слизнюк атакует вас - бегите",
	little_ooze_desc = "Спец-предупреждение, когда вас атакует Малый слизнюк",
})

BigWigsAPI.SetBossModuleLocale("Blood Prince Council", {
	warmup_trigger = "Глупые смертные. Думали, что одолели нас? Сан'лейн – непобедимые воины Короля-лича. Теперь наши силы едины!",
	empowered_flames_trigger = "Жаркое пламя тянется к (%S+)!",

	keleseth = "Принц Келесет",
	taldaram = "Принц Талдарам",
	valanar = "Принц Валанар",

	switch = "Смена цели",
	switch_desc = "Предупреждение о смене цели",
	switch_message = "Смените цель на: %s",
	switch_soon = "Скоро смена цели",
})

BigWigsAPI.SetBossModuleLocale("Blood-Queen Lana'thel", {
	swarming_shadows_trigger = "Тени собираются и окружают (%S+)!",
	frenzy_say = "Я голоден!",
})

BigWigsAPI.SetBossModuleLocale("Valithria Dreamwalker", {
	engage_trigger = "Чужаки ворвались во внутренние покои. Уничтожьте зеленого дракона! Пусть останутся лишь кости и прах для воскрешения!",
	portals_trigger = "Я открыла портал в Изумрудный Сон. Там вы найдете спасение, герои...",

	portals_open = "Открытие порталов",
	portals_close = "Закрытие порталов",
})

BigWigsAPI.SetBossModuleLocale("Sindragosa", {
	airphase_trigger = "Здесь ваше вторжение и окончится! Никто не уцелеет.",
	stage2_trigger = "А теперь почувствуйте всю мощь господина и погрузитесь в отчаяние!",

	airphase = "Воздушная фаза",
	airphase_desc = "Объявлять воздушную фазу",
	next_airphase = "След. воздушная фаза",
	next_groundphase = "След. наземная фаза",
	landing_soon = "Синдрагоса скоро приземлится",
})

BigWigsAPI.SetBossModuleLocale("The Lich King", {
	warmup_trigger = "Неужели прибыли наконец хваленые силы Света? Мне бросить Ледяную Скорбь и сдаться на твою милость, Фордринг?",

	roleplay = "Представление",
	valkyr_grabbed = "%s схватили!",
	valkyr_you = "Вас схватили",
	valkyr_low = "У Валь'киры меньше 55%",
	plague_jump = "Мертвящая чума перепрыгнула на %s",
})

BigWigsAPI.SetBossModuleLocale("Lady Jaina Proudmoore", {
	bossName = "Леди Джайна Праудмур",
})

BigWigsAPI.SetBossModuleLocale("Icecrown Citadel Trash", {
	warder_trigger1 = "Кто... идет?",
	warder_trigger2 = "Я пробудился...",
	warder_trigger3 = "В покои господина проникли!",
	fleshreaper_trigger1 = "Скорей, нападем на них сзади!",
	fleshreaper_trigger2 = "Вам не уйти от нас.",
	fleshreaper_trigger3 = "Живые? Здесь?!",
	gauntlet_trigger = "Они не должны прорваться к Синдрагосе! Скорее, остановите их!",

	trap_warder = "Ловушка активирована! - Заклятый страж освобожден",
	trap_warder_desc = "Спец-предупреждение для активации ловушки",
	trap_fleshreaper = "Ловушка активирована! - приближаются Мстительные свежеватели",
	trap_fleshreaper_desc = "Спец-предупреждение для активации ловушки",
	gauntlet = "Приближаются защитники Синдрагосы!",
	gauntlet_desc = "Спец-предупреждение для активации защитников Синдрагосы",
})

-- Naxxramas

BigWigsAPI.SetBossModuleLocale("Anub'Rekhan", {
	engage_trigger1 = "Бегите, бегите! Я люблю горячую кровь!",
	engage_trigger2 = "Посмотрим, какие вы на вкус!",
})

BigWigsAPI.SetBossModuleLocale("Grand Widow Faerlina", {
	-- engage_trigger: no Russian text in DBM Sirus
	embrace_expire = "Объятие Вдовы через 5 секунд",
})

BigWigsAPI.SetBossModuleLocale("Maexxna", {
	spiders = "Паученыши Мексны",
	spiders_desc = "Предупреждения и отсчет времени до Паученышей Мексны",
	spiders_soon = "Паученыши Мексны через 5 секунд",
	spiders_now = "В паутине появляются паучата",
	spiders_bar = "Паученыши Мексны",

	arachnophobia = "Арахнофобия",
	arachnophobia_desc = "Отсчет времени для Арахнофобия (достижение): убить Мексну за 20 минут после Ануб'Рекана",
})

BigWigsAPI.SetBossModuleLocale("Noth the Plaguebringer", {
	engage_trigger = "Смерть чужакам!",
	adds_trigger = "призывает скелетов-воинов!",
	adds2_trigger = "поднимает новых скелетов!",

	teleport = "Телепортация",
	teleport_desc = "Предупреждения и отсчет времени до телепортации",
	teleport_now = "Телепортация",
	teleport_soon = "Телепортация через 20 секунд",
	teleport_back = "Телепортация обратно",
})

BigWigsAPI.SetBossModuleLocale("Heigan the Unclean", {
	engage_trigger = "Теперь вы принадлежите мне!",

	teleport = "Телепортация",
	teleport_desc = "Предупреждения и отсчет времени до телепортации",
	teleport_now = "Телепортация",
	teleport_soon = "Телепортация через %d сек.",
})

BigWigsAPI.SetBossModuleLocale("Loatheb", {
	heal_soon = "Можно исцелять через 3 секунды",
	heal_now = "Исцеляйте сейчас",
})

BigWigsAPI.SetBossModuleLocale("Instructor Razuvious", {
	engage_trigger1 = "Покажите мне, на что способны!",
	engage_trigger2 = "Обучение окончено! Покажите мне, что вы усвоили!",
	engage_trigger3 = "Вспомните, чему я вас учил!",
	engage_trigger4 = "Выше ногу! Или у тебя с этим проблемы?",

	shield_wall_soon = "Стена костей закончится через 5 секунд",
})

BigWigsAPI.SetBossModuleLocale("Gothik the Harvester", {
	engage_trigger = "Глупо было искать свою смерть.",

	waves = "Волны",
	waves_desc = "Предупреждать перед следующей волной и отсчет времени до волны",
	wave_soon = "Волна %d: %s через 3 секунды",
	wave_spawned = "Призыв волны",
	wave_spawned_desc = "Предупреждение для волны призыва",
	wave_now = "Волна %d: %s призван",
	wave1 = "%d %s",
	wave2 = "%d %s и %d %s",
	wave3 = "%d %s, %d %s и %d %s",
	trainee = "Ученика",
	knight = "Рыцаря",
	rider = "Всадника",

	adds_down = "Всадники и рыцари",
	adds_down_desc = "Предупреждение, когда всадник или рыцарь мертв",
	rider_down = "Всадник мертв",
	knight_down = "Рыцарь мертв",

	gate = "Открытие ворот", -- DBM: not localized
	gate_desc = "Отсчет времени до открытия ворот",
})

BigWigsAPI.SetBossModuleLocale("The Four Horsemen", {
	mark_soon = "Знак %d через 3 секунды",
	mark_soon_desc = "Предупреждать перед следующими знаками",
})

BigWigsAPI.SetBossModuleLocale("Patchwerk", {
	engage_trigger1 = "Лоскутик хочет поиграть!",
	engage_trigger2 = "Кел'Тузад объявил Лоскутика воплощением войны!",
})

BigWigsAPI.SetBossModuleLocale("Thaddius", {
	engage_trigger = "Сталагг сокрушить вас!",
	overload_trigger = "%s перезагружается!",
	overload2_trigger = "Катушка Теслы перезагружается!",

	polarity_changed = "Полярность изменена",
	polarity_changed_desc = "Предупреждение, когда ваша полярность изменена",
	polarity_changed_msg = "Полярность изменена на %s",
	polarity_same = "Полярность не изменена",
	polarity_same_desc = "Предупреждение, когда ваша полярность не изменена",
	negative = "отрицательную",
	positive = "положительную",
})

BigWigsAPI.SetBossModuleLocale("Sapphiron", {
	breath_trigger = "%s глубоко вдыхает.",

	air = "Воздушная фаза",
	air_desc = "Объявлять Воздушную и Наземную фазы, отсчет времени до них",
	air_soon = "Воздушная фаза через 10 секунд",
	air_now = "Воздушная фаза",
	landed = "Сапфирон приземляется",
	landing = "Приземление",

	low_hp = "У Сапфирона нет сил взлететь",
	low_hp_desc = "Спец-предупреждения для 10% босса (отмена воздушной фазы)",
})

BigWigsAPI.SetBossModuleLocale("Kel'Thuzad", {
	engage_trigger = "Соратники, слуги, солдаты холодной тьмы! Повинуйтесь зову Кел'Тузада!",

	stage2_soon = "Кел'Тузад вступает в бой через 10 секунд",
	adds_soon = "Скоро прибытие Стражей Ледяной Короны",
})

-- Onyxia's Lair

BigWigsAPI.SetBossModuleLocale("Onyxia", {
	engage_trigger = "Вот это сюрприз. Обычно, чтобы найти обед, мне приходится покидать логово.",
	stage2_trigger = "Эта бессмысленная возня вгоняет меня в тоску. Я сожгу вас всех!",
	stage3_trigger = "Похоже, вам требуется преподать еще один урок, смертные!",

	whelps = "Вызов дракончиков Ониксии",
	whelps_desc = "Отсчет времени и предупреждения о дракончиках Ониксии",
	whelps_soon = "Скоро дракончики Ониксии",
})

-- The Eye of Eternity

BigWigsAPI.SetBossModuleLocale("Malygos", {
	engage_trigger = "Мое терпение лопнуло! Пора от вас избавиться!",
	stage2_trigger = "Я надеялся быстро с вами покончить",
	breath_trigger = "Пока я дышу, вам не добиться своего!",
	stage3_trigger = "Вот и ваши благодетели появились",
	spark_trigger = "Искра мощи появляется из ближайшей расселины!",
	surge_trigger = "%s уставился на вас!",
})

-- The Obsidian Sanctum

BigWigsAPI.SetBossModuleLocale("Sartharion", {
	wall_trigger = "Лава вокруг %s начинает бурлить!",
	portal_trigger = "%s открывает сумрачный портал!",
	tenebron = "Тенеброн",
	shadron = "Шадрон",
	vesperon = "Весперон",

	drakes = "Драконы",
	drakes_desc = "Отсчет времени до прибытия драконов и их способностей",
	tenebron_arrives = "Прибытие Тенеброна",
	shadron_arrives = "Прибытие Шадрона",
	vesperon_arrives = "Прибытие Весперона",
	tenebron_incoming = "Прибытие Тенеброна",
	shadron_incoming = "Прибытие Шадрона",
	vesperon_incoming = "Прибытие Весперона",
	whelps = "Тенебронские дракончики",
	whelps_soon = "Скоро дракончики тенеброна",
	shadron_portal = "Портал Шадрона",
	shadron_portal_soon = "Скоро портал Шадрон",
	vesperon_portal = "Портал Весперона",
	vesperon_portal2 = "Портал Весперона 2",
	reflect_soon = "Весперон: Скоро отражение",

	portals = "Порталы",
	portals_desc = "Спец-предупреждение для порталов драконов",
	tenebron_portal_msg = "Портал Тенеброна",
	shadron_portal_msg = "Портал Шадрона",
	vesperon_portal_msg = "Портал Весперона",
	fire_wall = "Огненная стена",
})

-- The Ruby Sanctum

BigWigsAPI.SetBossModuleLocale("Baltharus the Warborn", {
	bossName = "Балтар Рожденный в Битве",
	split_soon = "Скоро разделение",
})

BigWigsAPI.SetBossModuleLocale("Saviana Ragefire", {
	bossName = "Савиана Огненная Пропасть",
})

BigWigsAPI.SetBossModuleLocale("General Zarithrian", {
	bossName = "Генерал Заритриан",
	adds_trigger = "Слуги! Обратите их в пепел!",
	new_adds = "Новые помощники",
	adds_arrive = "Прибытие помощников",
})

BigWigsAPI.SetBossModuleLocale("Halion", {
	stage2_trigger = "В мире сумерек вы найдете лишь страдания! Входите, если посмеете!",
	stage3_trigger = "Я есть свет и я есть тьма! Трепещите, ничтожные, перед посланником Смертокрыла!",
	meteor_trigger = "Небеса в огне!",
	cutter_trigger = "Во вращающихся сферах пульсирует темная энергия!",
	cutter_cast = "Применение заклинания Лезвие сумерек: 5 сек",
})

-- Vault of Archavon

BigWigsAPI.SetBossModuleLocale("Archavon the Stone Watcher", {
	grab_trigger = "%%s бросается к (%S+)!",
	grab = "Аркавон хватает |3-1(>%s<)",
})

BigWigsAPI.SetBossModuleLocale("Emalon the Storm Watcher", {
	overcharge_explosion = "Взрыв в результате перегрузки",
})
