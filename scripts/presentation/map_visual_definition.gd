class_name MapVisualDefinition
extends RefCounted

const MAP_SIZE := Vector2(1600.0, 820.0)

static func create_default() -> Dictionary:
	var visuals: Dictionary = {}
	_add(visuals, "NA_01", [Vector2(55, 155), Vector2(105, 120), Vector2(175, 135), Vector2(205, 185), Vector2(170, 245), Vector2(100, 260), Vector2(50, 220)], Vector2(125, 184), Vector2(125, 212), [Vector2(195, 180)])
	_add(visuals, "NA_02", [Vector2(195, 125), Vector2(285, 105), Vector2(350, 135), Vector2(345, 205), Vector2(285, 230), Vector2(205, 190)], Vector2(270, 160), Vector2(270, 190))
	_add(visuals, "NA_03", [Vector2(495, 90), Vector2(585, 82), Vector2(665, 108), Vector2(720, 165), Vector2(675, 225), Vector2(590, 215), Vector2(530, 175)], Vector2(615, 137), Vector2(620, 175))
	_add(visuals, "NA_04", [Vector2(205, 205), Vector2(285, 215), Vector2(350, 245), Vector2(335, 320), Vector2(265, 335), Vector2(205, 285)], Vector2(265, 257), Vector2(270, 290))
	_add(visuals, "NA_05", [Vector2(350, 205), Vector2(445, 205), Vector2(500, 250), Vector2(490, 325), Vector2(405, 340), Vector2(335, 305), Vector2(340, 245)], Vector2(415, 248), Vector2(415, 292))
	_add(visuals, "NA_06", [Vector2(205, 305), Vector2(270, 330), Vector2(335, 315), Vector2(350, 390), Vector2(305, 445), Vector2(230, 425), Vector2(190, 365)], Vector2(270, 350), Vector2(270, 390))
	_add(visuals, "NA_07", [Vector2(350, 335), Vector2(430, 340), Vector2(500, 370), Vector2(490, 435), Vector2(420, 455), Vector2(345, 405)], Vector2(420, 375), Vector2(420, 415))
	_add(visuals, "NA_08", [Vector2(345, 430), Vector2(420, 450), Vector2(470, 500), Vector2(440, 545), Vector2(385, 515), Vector2(360, 470)], Vector2(410, 465), Vector2(415, 495))
	_add(visuals, "NA_09", [Vector2(445, 190), Vector2(515, 190), Vector2(575, 225), Vector2(565, 295), Vector2(505, 315), Vector2(485, 255)], Vector2(520, 220), Vector2(520, 260))

	_add(visuals, "SA_01", [Vector2(430, 525), Vector2(480, 505), Vector2(535, 535), Vector2(530, 595), Vector2(485, 620), Vector2(445, 580)], Vector2(482, 540), Vector2(482, 570))
	_add(visuals, "SA_02", [Vector2(535, 525), Vector2(600, 515), Vector2(665, 550), Vector2(690, 635), Vector2(650, 705), Vector2(575, 690), Vector2(530, 610)], Vector2(610, 570), Vector2(615, 620))
	_add(visuals, "SA_03", [Vector2(445, 585), Vector2(485, 620), Vector2(545, 610), Vector2(575, 690), Vector2(535, 735), Vector2(470, 690), Vector2(430, 640)], Vector2(485, 635), Vector2(500, 675))
	_add(visuals, "SA_04", [Vector2(470, 690), Vector2(535, 735), Vector2(575, 690), Vector2(610, 765), Vector2(575, 810), Vector2(510, 800), Vector2(465, 750)], Vector2(535, 745), Vector2(545, 775))

	_add(visuals, "EU_01", [Vector2(690, 160), Vector2(745, 145), Vector2(790, 175), Vector2(775, 225), Vector2(720, 245), Vector2(680, 215)], Vector2(732, 177), Vector2(735, 207))
	_add(visuals, "EU_02", [Vector2(790, 90), Vector2(850, 70), Vector2(910, 105), Vector2(925, 170), Vector2(885, 235), Vector2(825, 225), Vector2(790, 170)], Vector2(848, 120), Vector2(855, 165))
	_add(visuals, "EU_03", [Vector2(745, 235), Vector2(805, 220), Vector2(850, 260), Vector2(835, 325), Vector2(780, 345), Vector2(735, 300)], Vector2(790, 260), Vector2(795, 300))
	_add(visuals, "EU_04", [Vector2(835, 225), Vector2(910, 235), Vector2(970, 270), Vector2(950, 345), Vector2(875, 350), Vector2(830, 315)], Vector2(890, 260), Vector2(895, 305))
	_add(visuals, "EU_05", [Vector2(965, 235), Vector2(1060, 245), Vector2(1100, 305), Vector2(1060, 370), Vector2(990, 360), Vector2(950, 315)], Vector2(1010, 270), Vector2(1025, 315))
	_add(visuals, "EU_06", [Vector2(820, 345), Vector2(885, 345), Vector2(930, 385), Vector2(910, 450), Vector2(845, 455), Vector2(800, 405)], Vector2(855, 375), Vector2(860, 415))
	_add(visuals, "EU_07", [Vector2(910, 360), Vector2(985, 365), Vector2(1040, 405), Vector2(1010, 475), Vector2(945, 485), Vector2(900, 440)], Vector2(950, 395), Vector2(965, 435))

	_add(visuals, "AF_01", [Vector2(780, 455), Vector2(855, 445), Vector2(925, 475), Vector2(940, 545), Vector2(875, 575), Vector2(805, 540)], Vector2(835, 480), Vector2(855, 515))
	_add(visuals, "AF_02", [Vector2(925, 465), Vector2(995, 470), Vector2(1045, 510), Vector2(1030, 565), Vector2(955, 570), Vector2(925, 540)], Vector2(975, 490), Vector2(980, 530))
	_add(visuals, "AF_03", [Vector2(1015, 520), Vector2(1080, 520), Vector2(1140, 575), Vector2(1115, 660), Vector2(1045, 665), Vector2(1010, 600)], Vector2(1065, 555), Vector2(1075, 610))
	_add(visuals, "AF_04", [Vector2(875, 565), Vector2(955, 565), Vector2(1015, 610), Vector2(1000, 685), Vector2(925, 700), Vector2(880, 640)], Vector2(930, 600), Vector2(945, 645))
	_add(visuals, "AF_05", [Vector2(875, 695), Vector2(925, 700), Vector2(1000, 680), Vector2(1045, 735), Vector2(1010, 810), Vector2(920, 815), Vector2(865, 770)], Vector2(930, 725), Vector2(950, 765))
	_add(visuals, "AF_06", [Vector2(1115, 665), Vector2(1170, 675), Vector2(1200, 735), Vector2(1165, 795), Vector2(1110, 770), Vector2(1090, 715)], Vector2(1145, 690), Vector2(1145, 735))

	_add(visuals, "AS_01", [Vector2(1070, 230), Vector2(1150, 220), Vector2(1205, 270), Vector2(1180, 335), Vector2(1110, 350), Vector2(1060, 300)], Vector2(1115, 250), Vector2(1135, 295))
	_add(visuals, "AS_02", [Vector2(1185, 175), Vector2(1280, 170), Vector2(1340, 225), Vector2(1305, 300), Vector2(1220, 315), Vector2(1175, 270)], Vector2(1235, 205), Vector2(1250, 255))
	_add(visuals, "AS_03", [Vector2(1035, 355), Vector2(1105, 345), Vector2(1160, 390), Vector2(1145, 455), Vector2(1080, 485), Vector2(1030, 430)], Vector2(1075, 380), Vector2(1090, 425))
	_add(visuals, "AS_04", [Vector2(1150, 330), Vector2(1230, 315), Vector2(1300, 355), Vector2(1270, 435), Vector2(1195, 455), Vector2(1140, 405)], Vector2(1195, 350), Vector2(1215, 395))
	_add(visuals, "AS_05", [Vector2(1285, 345), Vector2(1365, 335), Vector2(1425, 375), Vector2(1400, 470), Vector2(1330, 495), Vector2(1270, 430)], Vector2(1325, 365), Vector2(1350, 420))
	_add(visuals, "AS_06", [Vector2(1335, 165), Vector2(1410, 150), Vector2(1475, 205), Vector2(1450, 275), Vector2(1380, 295), Vector2(1330, 245)], Vector2(1385, 190), Vector2(1405, 235))
	_add(visuals, "AS_07", [Vector2(1310, 285), Vector2(1380, 275), Vector2(1440, 320), Vector2(1425, 385), Vector2(1360, 405), Vector2(1310, 360)], Vector2(1355, 300), Vector2(1370, 345))
	_add(visuals, "AS_08", [Vector2(1235, 455), Vector2(1310, 450), Vector2(1360, 500), Vector2(1330, 585), Vector2(1260, 590), Vector2(1220, 525)], Vector2(1265, 480), Vector2(1290, 530))
	_add(visuals, "AS_09", [Vector2(1335, 490), Vector2(1410, 485), Vector2(1460, 540), Vector2(1435, 620), Vector2(1370, 635), Vector2(1330, 575)], Vector2(1375, 520), Vector2(1400, 575))
	_add(visuals, "AS_10", [Vector2(1450, 275), Vector2(1515, 270), Vector2(1550, 330), Vector2(1510, 405), Vector2(1440, 390), Vector2(1425, 330)], Vector2(1475, 300), Vector2(1485, 350))
	_add(visuals, "AS_11", [Vector2(1510, 145), Vector2(1570, 125), Vector2(1600, 175), Vector2(1595, 255), Vector2(1540, 280), Vector2(1495, 225)], Vector2(1545, 165), Vector2(1550, 210), [Vector2(1590, 200), Vector2(10, 200)])
	_add(visuals, "AS_12", [Vector2(1520, 405), Vector2(1575, 390), Vector2(1600, 435), Vector2(1595, 500), Vector2(1540, 515), Vector2(1505, 465)], Vector2(1545, 425), Vector2(1555, 465))

	_add(visuals, "OC_01", [Vector2(1320, 610), Vector2(1390, 620), Vector2(1445, 665), Vector2(1410, 715), Vector2(1340, 705), Vector2(1300, 660)], Vector2(1345, 635), Vector2(1370, 675))
	_add(visuals, "OC_02", [Vector2(1435, 615), Vector2(1505, 610), Vector2(1545, 650), Vector2(1515, 705), Vector2(1455, 700), Vector2(1420, 665)], Vector2(1465, 635), Vector2(1480, 670))
	_add(visuals, "OC_03", [Vector2(1380, 705), Vector2(1450, 710), Vector2(1505, 750), Vector2(1480, 815), Vector2(1400, 815), Vector2(1360, 770)], Vector2(1400, 730), Vector2(1430, 775))
	_add(visuals, "OC_04", [Vector2(1505, 710), Vector2(1575, 705), Vector2(1600, 750), Vector2(1600, 820), Vector2(1490, 815), Vector2(1480, 770)], Vector2(1530, 730), Vector2(1545, 775))
	return visuals

static func region_label_positions() -> Dictionary:
	return {
		"NA": Vector2(270, 105),
		"SA": Vector2(570, 545),
		"EU": Vector2(900, 170),
		"AF": Vector2(925, 520),
		"AS": Vector2(1320, 125),
		"OC": Vector2(1450, 590),
	}

static func _add(visuals: Dictionary, territory_id: String, points: Array, label_position: Vector2, marker_position: Vector2, anchors: Array = []) -> void:
	visuals[territory_id] = TerritoryVisualDefinition.new(territory_id, PackedVector2Array(points), label_position, marker_position, anchors)
