extends Node

signal ChangeLevel

var CurrentLevel : int = 0;
var CurrentLevelScene;

var LevelData : Dictionary = {
	# New Early-Game Levels 1-10
	1: preload("uid://blcmaj1t2lsax"),
	2: preload("uid://dnwf35rfeye1v"),
	3: preload("uid://djfmmw7uj4s3g"),
	4: preload("uid://dobdlhfuyt1ch"),
	5: preload("uid://bv6kn6ymg25ab"),
	6: preload("uid://nouh0jhg46jy"),
	7: preload("uid://bpq0011blrqpn"),
	8: preload("uid://cxm1tr8v0auuf"),
	9: preload("uid://cgw8ien5i4353"),
	10: preload("uid://cwsog6cunrn5u"),
	11: preload("uid://cvodw0yg6pjkq"),
	12: preload("uid://bb68eimn6ht8y"),
	13: preload("uid://d37fktcunnn1e"),
	14: preload("uid://6p3sgtylm6dn"),
	15: preload("uid://deqtndv8u6o7k"),
	16: preload("uid://ctyp6d243bhfo"),
	17: preload("uid://d0kf8jx2x6vk3")
}
